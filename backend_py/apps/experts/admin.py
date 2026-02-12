"""Experts admin configuration."""

from django.contrib import admin
from .models import Expert, ExpertReview


@admin.register(Expert)
class ExpertAdmin(admin.ModelAdmin):
    list_display = ['expert_id', 'full_name', 'title', 'rating', 'is_verified', 'created_at']
    search_fields = ['full_name', 'title']


@admin.register(ExpertReview)
class ExpertReviewAdmin(admin.ModelAdmin):
    list_display = ['review_id', 'expert_id', 'user_id', 'rating', 'created_at']
    list_filter = ['rating']
