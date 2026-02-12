"""
Expert service - Business logic for expert operations.
"""

import logging
from typing import Optional
from django.db import connection

from .models import Expert, ExpertReview

logger = logging.getLogger(__name__)


class ExpertService:
    """Service for expert-related operations."""

    @classmethod
    def get_experts(
        cls,
        q: Optional[str] = None,
        page: int = 1,
        page_size: int = 10,
    ):
        """Get paginated list of experts with optional search."""
        queryset = Expert.objects.all().order_by('-rating', '-consultation_count')

        if q:
            queryset = queryset.filter(full_name__icontains=q)

        total = queryset.count()
        offset = (page - 1) * page_size
        items = list(queryset[offset:offset + page_size])

        return {
            'page': page,
            'pageSize': page_size,
            'total': total,
            'items': items,
        }

    @classmethod
    def get_expert_detail(cls, expert_id: int):
        """Get single expert by ID."""
        try:
            return Expert.objects.get(expert_id=expert_id)
        except Expert.DoesNotExist:
            return None

    @classmethod
    def get_expert_reviews(
        cls,
        expert_id: int,
        page: int = 1,
        page_size: int = 10,
    ):
        """Get paginated reviews for an expert."""
        queryset = (
            ExpertReview.objects
            .filter(expert_id=expert_id)
            .order_by('-created_at')
        )

        total = queryset.count()
        offset = (page - 1) * page_size
        items = list(queryset[offset:offset + page_size])

        return {
            'page': page,
            'pageSize': page_size,
            'total': total,
            'items': items,
        }
