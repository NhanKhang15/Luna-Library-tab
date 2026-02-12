"""Video serializers for API endpoints."""

from rest_framework import serializers
from apps.experts.serializers import ExpertSerializer
from .models import Video, VideoStats


class ViewerStateSerializer(serializers.Serializer):
    """Viewer state (whether user liked the content)."""
    liked = serializers.BooleanField()


class VideoListItemSerializer(serializers.Serializer):
    """Serializer for video list items."""
    id = serializers.IntegerField(source='video_id')
    title = serializers.CharField()
    thumbnailUrl = serializers.CharField(source='thumbnail_url', allow_null=True)
    videoUrl = serializers.CharField(source='video_url')
    durationSeconds = serializers.IntegerField(source='duration_seconds')
    isShort = serializers.BooleanField(source='is_short')
    viewCount = serializers.SerializerMethodField()
    likeCount = serializers.SerializerMethodField()
    publishedAt = serializers.DateTimeField(source='published_at')
    isPremium = serializers.BooleanField(source='is_premium')
    expert = ExpertSerializer(allow_null=True)
    viewerState = serializers.SerializerMethodField()

    def get_viewCount(self, obj):
        try:
            return obj.stats.view_count if hasattr(obj, 'stats') and obj.stats else 0
        except VideoStats.DoesNotExist:
            return 0

    def get_likeCount(self, obj):
        try:
            return obj.stats.like_count if hasattr(obj, 'stats') and obj.stats else 0
        except VideoStats.DoesNotExist:
            return 0

    def get_viewerState(self, obj):
        liked = getattr(obj, '_viewer_liked', False)
        return {'liked': liked}


class VideoDetailSerializer(serializers.Serializer):
    """Serializer for video detail."""
    id = serializers.IntegerField(source='video_id')
    title = serializers.CharField()
    description = serializers.CharField(allow_null=True)
    thumbnailUrl = serializers.CharField(source='thumbnail_url', allow_null=True)
    videoUrl = serializers.CharField(source='video_url')
    durationSeconds = serializers.IntegerField(source='duration_seconds')
    isShort = serializers.BooleanField(source='is_short')
    categories = serializers.SerializerMethodField()
    publishedAt = serializers.DateTimeField(source='published_at')
    viewCount = serializers.SerializerMethodField()
    likeCount = serializers.SerializerMethodField()
    isPremium = serializers.BooleanField(source='is_premium')
    expert = ExpertSerializer(allow_null=True)
    viewerState = serializers.SerializerMethodField()

    def get_categories(self, obj):
        return [vc.category.name for vc in obj.video_categories.all() if vc.category]

    def get_viewCount(self, obj):
        return getattr(obj, '_view_count', 0)

    def get_likeCount(self, obj):
        return getattr(obj, '_like_count', 0)

    def get_viewerState(self, obj):
        liked = getattr(obj, '_viewer_liked', False)
        return {'liked': liked}


class VideoListResponseSerializer(serializers.Serializer):
    """Paginated video list response."""
    page = serializers.IntegerField()
    pageSize = serializers.IntegerField()
    total = serializers.IntegerField()
    items = VideoListItemSerializer(many=True)


class LikeToggleResponseSerializer(serializers.Serializer):
    """Like toggle response."""
    liked = serializers.BooleanField()
    likeCount = serializers.IntegerField()


class RelatedContentItemSerializer(serializers.Serializer):
    """Related content item (post or video)."""
    id = serializers.IntegerField()
    type = serializers.CharField()
    title = serializers.CharField()
    thumbnailUrl = serializers.CharField(allow_null=True)


class RelatedContentResponseSerializer(serializers.Serializer):
    """Related content response."""
    page = serializers.IntegerField()
    pageSize = serializers.IntegerField()
    total = serializers.IntegerField()
    items = RelatedContentItemSerializer(many=True)
