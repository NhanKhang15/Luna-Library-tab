"""
Database context retrieval for RAG.
Searches Posts and Videos tables for content relevant to the user's question.
"""

import os
import pyodbc
from dotenv import load_dotenv

load_dotenv()


def get_connection_string() -> str:
    return (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={os.getenv('DB_HOST', 'localhost')};"
        f"DATABASE={os.getenv('DB_NAME', 'Floria_2')};"
        f"UID={os.getenv('DB_USER', 'sa')};"
        f"PWD={os.getenv('DB_PASSWORD', '')};"
        f"TrustServerCertificate=yes;"
    )


def get_relevant_content(query: str, max_results: int = 5) -> str:
    """
    Search Posts and Videos by keywords from the user's message.
    Returns a formatted context string for the Gemini prompt.
    """
    keywords = [w.strip() for w in query.split() if len(w.strip()) >= 2]
    if not keywords:
        return ""

    context_parts = []

    try:
        conn = pyodbc.connect(get_connection_string())
        cursor = conn.cursor()

        # Build LIKE conditions for each keyword
        like_conditions = " OR ".join(
            ["(p.title LIKE ? OR p.summary LIKE ? OR p.content LIKE ?)"] * len(keywords)
        )
        params = []
        for kw in keywords:
            term = f"%{kw}%"
            params.extend([term, term, term])

        # Search Posts
        cursor.execute(f"""
            SELECT TOP (?) p.title, p.summary, 
                   LEFT(p.content, 500) as content_preview
            FROM Posts p
            WHERE p.status = 'published' AND ({like_conditions})
            ORDER BY p.published_at DESC
        """, [max_results] + params)

        posts = cursor.fetchall()
        if posts:
            context_parts.append("=== BÀI VIẾT LIÊN QUAN ===")
            for row in posts:
                title = row[0] or ""
                summary = row[1] or ""
                content = row[2] or ""
                context_parts.append(
                    f"📝 {title}\n"
                    f"   Tóm tắt: {summary}\n"
                    f"   Nội dung: {content}..."
                )

        # Search Videos
        like_conditions_v = " OR ".join(
            ["(v.title LIKE ? OR v.description LIKE ?)"] * len(keywords)
        )
        params_v = []
        for kw in keywords:
            term = f"%{kw}%"
            params_v.extend([term, term])

        cursor.execute(f"""
            SELECT TOP (?) v.title, v.description
            FROM Videos v
            WHERE v.status = 'published' AND ({like_conditions_v})
            ORDER BY v.published_at DESC
        """, [max_results] + params_v)

        videos = cursor.fetchall()
        if videos:
            context_parts.append("\n=== VIDEO LIÊN QUAN ===")
            for row in videos:
                title = row[0] or ""
                desc = row[1] or ""
                context_parts.append(
                    f"🎥 {title}\n"
                    f"   Mô tả: {desc}"
                )

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"[chat/db_context] DB error: {e}")
        return ""

    return "\n".join(context_parts)
