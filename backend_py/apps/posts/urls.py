"""Posts URL configuration."""

from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_posts, name='posts-list'),
    path('<int:post_id>', views.get_post_detail, name='posts-detail'),
    path('<int:post_id>/like', views.toggle_like, name='posts-like'),
    path('<int:post_id>/related', views.get_related_content, name='posts-related'),
]
