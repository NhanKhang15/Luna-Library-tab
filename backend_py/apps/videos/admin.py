"""Videos admin configuration."""

from django.contrib import admin
from .models import Video, VideoStats, VideoLike


@admin.register(Video)
class VideoAdmin(admin.ModelAdmin):
    list_display = ['video_id', 'title', 'status', 'is_short', 'is_premium', 'published_at']
    list_filter = ['status', 'is_short', 'is_premium']
    search_fields = ['title']


@admin.register(VideoStats)
class VideoStatsAdmin(admin.ModelAdmin):
    list_display = ['video', 'view_count', 'like_count', 'updated_at']
