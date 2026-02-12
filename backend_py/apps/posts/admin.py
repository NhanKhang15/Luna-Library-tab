"""Posts admin configuration."""

from django.contrib import admin
from .models import Post, PostStats, PostLike, PostCategory, PostTag


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['post_id', 'title', 'status', 'is_premium', 'published_at']
    list_filter = ['status', 'is_premium']
    search_fields = ['title']


@admin.register(PostStats)
class PostStatsAdmin(admin.ModelAdmin):
    list_display = ['post', 'view_count', 'like_count', 'updated_at']
