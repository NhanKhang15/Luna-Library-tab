"""FAQ serializers."""

from rest_framework import serializers
from apps.experts.serializers import ExpertSerializer
from apps.tags.serializers import TagSerializer
from apps.videos.models import Video


class FAQSourcePostSerializer(serializers.Serializer):
    """Minimal post info for FAQ citation."""
    id = serializers.IntegerField(source='post_id')
    title = serializers.CharField()
    thumbnailUrl = serializers.CharField(source='thumbnail_url', allow_null=True)


class FAQRelatedVideoSerializer(serializers.Serializer):
    """Minimal video info for FAQ related content."""
    id = serializers.IntegerField(source='video_id')
    title = serializers.CharField()
    thumbnailUrl = serializers.CharField(source='thumbnail_url', allow_null=True)


class FAQItemSerializer(serializers.Serializer):
    """Full FAQ item serializer."""
    id = serializers.IntegerField(source='faq_id')
    category = serializers.CharField()
    question = serializers.CharField()
    answer = serializers.CharField()
    tags = serializers.SerializerMethodField()
    expert = ExpertSerializer(allow_null=True)
    sourcePost = serializers.SerializerMethodField()
    relatedVideos = serializers.SerializerMethodField()

    def get_tags(self, obj):
        tags = obj.tags.all()
        return TagSerializer(tags, many=True).data

    def get_sourcePost(self, obj):
        if obj.source_post:
            return FAQSourcePostSerializer(obj.source_post).data
        return None

    def get_relatedVideos(self, obj):
        """Find videos that share tags with this FAQ."""
        tag_ids = obj.tags.values_list('tag_id', flat=True)
        if not tag_ids:
            return []
        videos = Video.objects.filter(
            tags__tag_id__in=tag_ids
        ).distinct()[:3]
        return FAQRelatedVideoSerializer(videos, many=True).data


class FAQListResponseSerializer(serializers.Serializer):
    """FAQ list response."""
    category = serializers.CharField()
    items = FAQItemSerializer(many=True)
