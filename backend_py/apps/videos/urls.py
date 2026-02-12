"""Videos URL configuration."""

from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_videos, name='videos-list'),
    path('<int:video_id>', views.get_video_detail, name='videos-detail'),
    path('<int:video_id>/like', views.toggle_like, name='videos-like'),
    path('<int:video_id>/related', views.get_related_content, name='videos-related'),
]
