"""
FastAPI Service Layer - High-performance APIs for search and analytics.
Communicates with the same SQL Server database as Django.

Run with: uvicorn services.main:app --port 8002 --reload
"""

import os
from contextlib import asynccontextmanager
from typing import Optional, List
from datetime import datetime

import pyodbc
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()


# Database connection string
def get_connection_string():
    return (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={os.getenv('DB_HOST', 'localhost')};"
        f"DATABASE={os.getenv('DB_NAME', 'Floria_2')};"
        f"UID={os.getenv('DB_USER', 'sa')};"
        f"PWD={os.getenv('DB_PASSWORD', '')};"
        f"TrustServerCertificate=yes;"
    )


# Pydantic models
class SearchResultItem(BaseModel):
    id: int
    type: str  # 'post' or 'video'
    title: str
    thumbnailUrl: Optional[str]
    viewCount: int
    likeCount: int


class SearchResponse(BaseModel):
    query: str
    total: int
    items: List[SearchResultItem]


class AnalyticsSummary(BaseModel):
    totalPosts: int
    totalVideos: int
    totalViews: int
    totalLikes: int
    topPosts: List[dict]
    topVideos: List[dict]


# App lifecycle
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("FastAPI Search & Analytics Service starting...")
    yield
    # Shutdown
    print("FastAPI Service shutting down...")


# FastAPI app
app = FastAPI(
    title="Floria FastAPI Service",
    description="High-performance search and analytics APIs",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from services.chat.router import router as chat_router


@app.get("/")
async def root():
    return {"message": "Floria FastAPI Service", "status": "running"}


# Chat AI endpoints
app.include_router(chat_router, prefix="/chat", tags=["Chat AI"])


@app.get("/api/search", response_model=SearchResponse)
async def search(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(20, ge=1, le=50, description="Max results")
):
    """
    Combined search across posts and videos.
    Uses direct SQL for optimal performance.
    """
    if not q.strip():
        raise HTTPException(status_code=400, detail="Search query cannot be empty")
    
    search_term = f"%{q.strip()}%"
    items = []
    
    try:
        conn = pyodbc.connect(get_connection_string())
        cursor = conn.cursor()
        
        # Search posts
        cursor.execute("""
            SELECT TOP (?) 
                p.post_id, p.title, p.thumbnail_url,
                COALESCE(ps.view_count, 0) as view_count,
                COALESCE(ps.like_count, 0) as like_count,
                COALESCE(e.full_name, 'Chuyên gia') as author_name
            FROM Posts p
            LEFT JOIN PostStats ps ON p.post_id = ps.post_id
            LEFT JOIN Experts e ON p.expert_id = e.expert_id
            WHERE p.status = 'published' 
              AND (p.title LIKE ? OR p.summary LIKE ?)
            ORDER BY COALESCE(ps.view_count, 0) + COALESCE(ps.like_count, 0) DESC
        """, (limit // 2, search_term, search_term))
        
        for row in cursor.fetchall():
            items.append(SearchResultItem(
                id=row[0],
                type='post',
                title=row[1],
                thumbnailUrl=row[2],
                viewCount=row[3],
                likeCount=row[4],
                authorName=row[5]
            ))
        
        # Search videos
        cursor.execute("""
            SELECT TOP (?) 
                v.video_id, v.title, v.thumbnail_url,
                COALESCE(vs.view_count, 0) as view_count,
                COALESCE(vs.like_count, 0) as like_count,
                COALESCE(e.full_name, 'Chuyên gia') as author_name
            FROM Videos v
            LEFT JOIN VideoStats vs ON v.video_id = vs.video_id
            LEFT JOIN Experts e ON v.expert_id = e.expert_id
            WHERE v.status = 'published' 
              AND (v.title LIKE ? OR v.description LIKE ?)
            ORDER BY COALESCE(vs.view_count, 0) + COALESCE(vs.like_count, 0) DESC
        """, (limit // 2, search_term, search_term))
        
        for row in cursor.fetchall():
            items.append(SearchResultItem(
                id=row[0],
                type='video',
                title=row[1],
                thumbnailUrl=row[2],
                viewCount=row[3],
                likeCount=row[4],
                authorName=row[5]
            ))
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    
    # Sort combined results by engagement
    items.sort(key=lambda x: x.viewCount + x.likeCount, reverse=True)
    items = items[:limit]
    
    return SearchResponse(
        query=q,
        total=len(items),
        items=items
    )


@app.get("/api/analytics/summary", response_model=AnalyticsSummary)
async def analytics_summary():
    """
    Get overall analytics summary.
    Aggregates views and likes across all content.
    """
    try:
        conn = pyodbc.connect(get_connection_string())
        cursor = conn.cursor()
        
        # Total counts
        cursor.execute("SELECT COUNT(*) FROM Posts WHERE status = 'published'")
        total_posts = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Videos WHERE status = 'published'")
        total_videos = cursor.fetchone()[0]
        
        # Total views and likes
        cursor.execute("""
            SELECT 
                COALESCE(SUM(view_count), 0),
                COALESCE(SUM(like_count), 0)
            FROM (
                SELECT view_count, like_count FROM PostStats
                UNION ALL
                SELECT view_count, like_count FROM VideoStats
            ) combined
        """)
        row = cursor.fetchone()
        total_views = row[0]
        total_likes = row[1]
        
        # Top posts
        cursor.execute("""
            SELECT TOP 5 
                p.post_id, p.title,
                COALESCE(ps.view_count, 0) as views,
                COALESCE(ps.like_count, 0) as likes
            FROM Posts p
            LEFT JOIN PostStats ps ON p.post_id = ps.post_id
            WHERE p.status = 'published'
            ORDER BY COALESCE(ps.view_count, 0) + COALESCE(ps.like_count, 0) DESC
        """)
        top_posts = [
            {"id": row[0], "title": row[1], "views": row[2], "likes": row[3]}
            for row in cursor.fetchall()
        ]
        
        # Top videos
        cursor.execute("""
            SELECT TOP 5 
                v.video_id, v.title,
                COALESCE(vs.view_count, 0) as views,
                COALESCE(vs.like_count, 0) as likes
            FROM Videos v
            LEFT JOIN VideoStats vs ON v.video_id = vs.video_id
            WHERE v.status = 'published'
            ORDER BY COALESCE(vs.view_count, 0) + COALESCE(vs.like_count, 0) DESC
        """)
        top_videos = [
            {"id": row[0], "title": row[1], "views": row[2], "likes": row[3]}
            for row in cursor.fetchall()
        ]
        
        cursor.close()
        conn.close()
        
        return AnalyticsSummary(
            totalPosts=total_posts,
            totalVideos=total_videos,
            totalViews=total_views,
            totalLikes=total_likes,
            topPosts=top_posts,
            topVideos=top_videos
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    try:
        conn = pyodbc.connect(get_connection_string())
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": str(e)}
