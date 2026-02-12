"""Experts URL configuration."""

from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_experts, name='experts-list'),
    path('<int:expert_id>/', views.get_expert_detail, name='experts-detail'),
    path('<int:expert_id>/reviews/', views.get_expert_reviews, name='experts-reviews'),
]
