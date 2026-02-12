"""
Video service - Business logic for video operations.
"""

import logging
import random
from datetime import datetime
from typing import Optional, Dict, Any
from django.db.models import F

from .models import Video, VideoStats, VideoLike, VideoCategory

logger = logging.getLogger(__name__)


class VideoService:
    """Service for video-related operations."""

    @classmethod
    def get_videos(
        cls,
        q: Optional[str] = None,
        sort: Optional[str] = None,
        page: int = 1,
        page_size: int = 10,
        premium: Optional[bool] = None,
        is_short: Optional[bool] = None,
        tag_name: Optional[str] = None,
        user_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """Get paginated list of videos with filters."""
        # Clamp values
        page_size = max(1, min(50, page_size))
        page = max(1, page)

        # Base query - published videos only
        queryset = Video.objects.filter(status='published').select_related('expert', 'stats')

        # Search filter
        if q:
            search_term = q.strip().lower()
            queryset = queryset.filter(title__icontains=search_term)

        # Premium filter
        if premium is not None:
            queryset = queryset.filter(is_premium=premium)

        # Short filter
        if is_short is not None:
            queryset = queryset.filter(is_short=is_short)

        # Tag filter
        if tag_name:
            queryset = queryset.filter(video_tags__tag__name=tag_name)

        # Total count
        total = queryset.count()

        # Sorting
        sort_key = (sort or 'TRENDING').upper()
        if sort_key == 'NEWEST':
            queryset = queryset.order_by('-published_at')
        elif sort_key == 'MOST_VIEWED':
            queryset = queryset.order_by(F('stats__view_count').desc(nulls_last=True), '-published_at')
        elif sort_key == 'MOST_LIKED':
            queryset = queryset.order_by(F('stats__like_count').desc(nulls_last=True), '-published_at')
        elif sort_key == 'TRENDING':
            queryset = queryset.order_by('-published_at')
        else:
            raise ValueError(f"Invalid sort: {sort}. Valid values: TRENDING, NEWEST, MOST_VIEWED, MOST_LIKED")

        # Pagination
        offset = (page - 1) * page_size
        videos = list(queryset[offset:offset + page_size])

        # Get viewer liked state in batch
        liked_video_ids = set()
        if user_id and videos:
            video_ids = [v.video_id for v in videos]
            liked_video_ids = set(
                VideoLike.objects.filter(user_id=user_id, video_id__in=video_ids)
                .values_list('video_id', flat=True)
            )

        # Add viewer state to videos
        for video in videos:
            video._viewer_liked = video.video_id in liked_video_ids

        return {
            'page': page,
            'pageSize': page_size,
            'total': total,
            'items': videos
        }

    @classmethod
    def get_video_detail(cls, video_id: int, user_id: Optional[int] = None) -> Optional[Video]:
        """Get video detail and increment view count."""
        try:
            video = Video.objects.select_related('expert', 'stats').prefetch_related(
                'video_categories__category'
            ).get(video_id=video_id, status='published')
        except Video.DoesNotExist:
            return None

        # Atomic view count increment
        VideoStats.objects.filter(video_id=video_id).update(
            view_count=F('view_count') + 1,
            updated_at=datetime.utcnow()
        )

        # Get updated stats
        try:
            stats = VideoStats.objects.get(video_id=video_id)
            video._view_count = stats.view_count
            video._like_count = stats.like_count
        except VideoStats.DoesNotExist:
            video._view_count = 1
            video._like_count = 0

        # Get viewer liked state
        video._viewer_liked = False
        if user_id:
            video._viewer_liked = VideoLike.objects.filter(
                user_id=user_id, video_id=video_id
            ).exists()

        return video

    @classmethod
    def toggle_like(cls, video_id: int, user_id: int) -> Dict[str, Any]:
        """Toggle like on a video."""
        # Check video exists
        if not Video.objects.filter(video_id=video_id).exists():
            raise ValueError(f"Video with id {video_id} not found")

        # Check current like status
        existing_like = VideoLike.objects.filter(user_id=user_id, video_id=video_id).first()

        if existing_like:
            # Unlike: remove like
            existing_like.delete()
            VideoStats.objects.filter(video_id=video_id).update(
                like_count=F('like_count') - 1,
                updated_at=datetime.utcnow()
            )
            liked = False
        else:
            # Like: add like
            VideoLike.objects.create(
                user_id=user_id,
                video_id=video_id,
                created_at=datetime.utcnow()
            )
            VideoStats.objects.filter(video_id=video_id).update(
                like_count=F('like_count') + 1,
                updated_at=datetime.utcnow()
            )
            liked = True

        # Get updated like count
        try:
            stats = VideoStats.objects.get(video_id=video_id)
            like_count = max(0, stats.like_count)
        except VideoStats.DoesNotExist:
            like_count = 1 if liked else 0

        return {
            'liked': liked,
            'likeCount': like_count
        }

    @classmethod
    def get_related_content(cls, video_id: int, page: int = 1, page_size: int = 6) -> Dict[str, Any]:
        """Get related posts and videos by category."""
        from apps.posts.models import Post, PostCategory

        page_size = max(1, min(20, page_size))
        page = max(1, page)

        # Get category IDs from the current video
        category_ids = list(
            VideoCategory.objects.filter(video_id=video_id)
            .values_list('category_id', flat=True)
        )

        if not category_ids:
            return {
                'page': page,
                'pageSize': page_size,
                'total': 0,
                'items': []
            }

        # Get related videos (exclude current)
        related_videos = list(
            Video.objects.filter(
                status='published',
                video_categories__category_id__in=category_ids
            ).exclude(video_id=video_id)
            .order_by('-published_at')
            .values('video_id', 'title', 'thumbnail_url')
            .distinct()
        )

        # Get related posts
        related_posts = list(
            Post.objects.filter(
                status='published',
                post_categories__category_id__in=category_ids
            )
            .order_by('-published_at')
            .values('post_id', 'title', 'thumbnail_url')
            .distinct()
        )

        # Combine and format
        items = []
        for v in related_videos:
            items.append({
                'id': v['video_id'],
                'type': 'video',
                'title': v['title'],
                'thumbnailUrl': v['thumbnail_url']
            })
        for p in related_posts:
            items.append({
                'id': p['post_id'],
                'type': 'post',
                'title': p['title'],
                'thumbnailUrl': p['thumbnail_url']
            })

        # Shuffle and paginate
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
