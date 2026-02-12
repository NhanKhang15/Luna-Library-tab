"""Tags admin configuration."""

from django.contrib import admin
from .models import Tag, ContentCategory


@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ['tag_id', 'name', 'slug', 'created_at']
    search_fields = ['name']


@admin.register(ContentCategory)
class ContentCategoryAdmin(admin.ModelAdmin):
    list_display = ['category_id', 'name', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name']
