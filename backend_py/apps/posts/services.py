"""
Post service - Business logic for post operations.
"""

import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
from django.db.models import F
from django.db import connection

from .models import Post, PostStats, PostLike, PostCategory

logger = logging.getLogger(__name__)


class PostService:
    """Service for post-related operations."""

    # Valid sort options
    SORT_OPTIONS = {
        'TRENDING': lambda q: q.extra(
            select={'_score': 'COALESCE(ps.like_count, 0) + COALESCE(ps.view_count, 0)'},
            tables=['PostStats AS ps'],
            where=['ps.post_id = Posts.post_id'],
        ).order_by('-_score', '-published_at'),
        'NEWEST': lambda q: q.order_by('-published_at'),
        'MOST_VIEWED': lambda q: q.order_by('-stats__view_count', '-published_at'),
        'MOST_LIKED': lambda q: q.order_by('-stats__like_count', '-published_at'),
    }

    @classmethod
    def get_posts(
        cls,
        q: Optional[str] = None,
        sort: Optional[str] = None,
        page: int = 1,
        page_size: int = 10,
        premium: Optional[bool] = None,
        tag_name: Optional[str] = None,
        user_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """Get paginated list of posts with filters."""
        # Clamp values
        page_size = max(1, min(50, page_size))
        page = max(1, page)

        # Base query - published posts only
        queryset = Post.objects.filter(status='published').select_related('expert', 'stats')

        # Search filter
        if q:
            search_term = q.strip().lower()
            queryset = queryset.filter(title__icontains=search_term) | \
                       queryset.filter(summary__icontains=search_term)

        # Premium filter
        if premium is not None:
            queryset = queryset.filter(is_premium=premium)

        # Tag filter
        if tag_name:
            queryset = queryset.filter(post_tags__tag__name=tag_name)

        # Total count
        total = queryset.count()

        # Sorting
        sort_key = (sort or 'TRENDING').upper()
        if sort_key not in cls.SORT_OPTIONS:
            raise ValueError(f"Invalid sort: {sort}. Valid values: TRENDING, NEWEST, MOST_VIEWED, MOST_LIKED")

        # Apply simple sorting without extra() for SQL Server compatibility
        if sort_key == 'NEWEST':
            queryset = queryset.order_by('-published_at')
        elif sort_key == 'MOST_VIEWED':
            queryset = queryset.order_by(F('stats__view_count').desc(nulls_last=True), '-published_at')
        elif sort_key == 'MOST_LIKED':
            queryset = queryset.order_by(F('stats__like_count').desc(nulls_last=True), '-published_at')
        else:  # TRENDING
            queryset = queryset.order_by('-published_at')  # Fallback, enhance with annotation if needed

        # Pagination
        offset = (page - 1) * page_size
        posts = list(queryset[offset:offset + page_size])

        # Get viewer liked state in batch
        liked_post_ids = set()
        if user_id and posts:
            post_ids = [p.post_id for p in posts]
            liked_post_ids = set(
                PostLike.objects.filter(user_id=user_id, post_id__in=post_ids)
                .values_list('post_id', flat=True)
            )

        # Add viewer state to posts
        for post in posts:
            post._viewer_liked = post.post_id in liked_post_ids

        return {
            'page': page,
            'pageSize': page_size,
            'total': total,
            'items': posts
        }

    @classmethod
    def get_post_detail(cls, post_id: int, user_id: Optional[int] = None) -> Optional[Post]:
        """Get post detail and increment view count."""
        try:
            post = Post.objects.select_related('expert', 'stats').prefetch_related(
                'post_categories__category'
            ).get(post_id=post_id, status='published')
        except Post.DoesNotExist:
            return None

        # Atomic view count increment
        PostStats.objects.filter(post_id=post_id).update(
            view_count=F('view_count') + 1,
            updated_at=datetime.utcnow()
        )

        # Get updated stats
        try:
            stats = PostStats.objects.get(post_id=post_id)
            post._view_count = stats.view_count
            post._like_count = stats.like_count
        except PostStats.DoesNotExist:
            post._view_count = 1
            post._like_count = 0

        # Get viewer liked state
        post._viewer_liked = False
        if user_id:
            post._viewer_liked = PostLike.objects.filter(
                user_id=user_id, post_id=post_id
            ).exists()

        return post

    @classmethod
    def toggle_like(cls, post_id: int, user_id: int) -> Dict[str, Any]:
        """Toggle like on a post."""
        # Check post exists
        if not Post.objects.filter(post_id=post_id).exists():
            raise ValueError(f"Post with id {post_id} not found")

        # Check current like status
        existing_like = PostLike.objects.filter(user_id=user_id, post_id=post_id).first()

        if existing_like:
            # Unlike: remove like
            existing_like.delete()
            PostStats.objects.filter(post_id=post_id).update(
                like_count=F('like_count') - 1,
                updated_at=datetime.utcnow()
            )
            liked = False
        else:
            # Like: add like
            PostLike.objects.create(
                user_id=user_id,
                post_id=post_id,
                created_at=datetime.utcnow()
            )
            PostStats.objects.filter(post_id=post_id).update(
                like_count=F('like_count') + 1,
                updated_at=datetime.utcnow()
            )
            liked = True

        # Get updated like count
        try:
            stats = PostStats.objects.get(post_id=post_id)
            like_count = max(0, stats.like_count)
        except PostStats.DoesNotExist:
            like_count = 1 if liked else 0

        return {
            'liked': liked,
            'likeCount': like_count
        }

    @classmethod
    def get_related_content(cls, post_id: int, page: int = 1, page_size: int = 6) -> Dict[str, Any]:
        """Get related posts and videos by category."""
        from apps.videos.models import Video, VideoCategory

        page_size = max(1, min(20, page_size))
        page = max(1, page)

        # Get category IDs from the current post
        category_ids = list(
            PostCategory.objects.filter(post_id=post_id)
            .values_list('category_id', flat=True)
        )

        if not category_ids:
            return {
                'page': page,
                'pageSize': page_size,
                'total': 0,
                'items': []
            }

        # Get related posts
        related_posts = list(
            Post.objects.filter(
                status='published',
                post_categories__category_id__in=category_ids
            ).exclude(post_id=post_id)
            .order_by('-published_at')
            .values('post_id', 'title', 'thumbnail_url')
            .distinct()
        )

        # Get related videos
        related_videos = list(
            Video.objects.filter(
                status='published',
                video_categories__category_id__in=category_ids
            )
            .order_by('-published_at')
            .values('video_id', 'title', 'thumbnail_url')
            .distinct()
        )

        # Combine and format
        items = []
        for p in related_posts:
            items.append({
                'id': p['post_id'],
                'type': 'post',
                'title': p['title'],
                'thumbnailUrl': p['thumbnail_url']
            })
        for v in related_videos:
            items.append({
                'id': v['video_id'],
                'type': 'video',
                'title': v['title'],
                'thumbnailUrl': v['thumbnail_url']
            })

        # Shuffle and paginate
        import random
        random.shuffle(items)
        total = len(items)
        offset = (page - 1) * page_size
        paged_items = items[offset:offset + page_size]

        return {
            'page': page,
            'pageSize': page_size,
            'total': total,
            'items': paged_items
        }
