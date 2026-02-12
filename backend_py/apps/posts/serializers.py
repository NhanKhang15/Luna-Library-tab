"""Post serializers for API endpoints."""

from rest_framework import serializers
from apps.experts.serializers import ExpertSerializer
from .models import Post, PostStats


class ViewerStateSerializer(serializers.Serializer):
    """Viewer state (whether user liked the content)."""
    liked = serializers.BooleanField()


class PostListItemSerializer(serializers.Serializer):
    """Serializer for post list items."""
    id = serializers.IntegerField(source='post_id')
    title = serializers.CharField()
    thumbnailUrl = serializers.CharField(source='thumbnail_url', allow_null=True)
    viewCount = serializers.SerializerMethodField()
    likeCount = serializers.SerializerMethodField()
    publishedAt = serializers.DateTimeField(source='published_at')
    isPremium = serializers.BooleanField(source='is_premium')
    expert = ExpertSerializer(allow_null=True)
    viewerState = serializers.SerializerMethodField()

    def get_viewCount(self, obj):
        try:
            return obj.stats.view_count if hasattr(obj, 'stats') and obj.stats else 0
        except PostStats.DoesNotExist:
            return 0

    def get_likeCount(self, obj):
        try:
            return obj.stats.like_count if hasattr(obj, 'stats') and obj.stats else 0
        except PostStats.DoesNotExist:
            return 0

    def get_viewerState(self, obj):
        liked = getattr(obj, '_viewer_liked', False)
        return {'liked': liked}


class PostContentSerializer(serializers.Serializer):
    """Post content (summary + body)."""
    summary = serializers.CharField(allow_null=True)
    body = serializers.CharField(source='content')


class PostDetailSerializer(serializers.Serializer):
    """Serializer for post detail."""
    id = serializers.IntegerField(source='post_id')
    title = serializers.CharField()
    thumbnailUrl = serializers.CharField(source='thumbnail_url', allow_null=True)
    categories = serializers.SerializerMethodField()
    publishedAt = serializers.DateTimeField(source='published_at')
    viewCount = serializers.SerializerMethodField()
    likeCount = serializers.SerializerMethodField()
    isPremium = serializers.BooleanField(source='is_premium')
    expert = ExpertSerializer(allow_null=True)
    content = serializers.SerializerMethodField()
    viewerState = serializers.SerializerMethodField()

    def get_categories(self, obj):
        return [pc.category.name for pc in obj.post_categories.all() if pc.category]

    def get_viewCount(self, obj):
        return getattr(obj, '_view_count', 0)

    def get_likeCount(self, obj):
        return getattr(obj, '_like_count', 0)

    def get_content(self, obj):
        return {
            'summary': obj.summary,
            'body': obj.content
        }

    def get_viewerState(self, obj):
        liked = getattr(obj, '_viewer_liked', False)
        return {'liked': liked}


class PostListResponseSerializer(serializers.Serializer):
    """Paginated post list response."""
    page = serializers.IntegerField()
    pageSize = serializers.IntegerField()
    total = serializers.IntegerField()
    items = PostListItemSerializer(many=True)


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
