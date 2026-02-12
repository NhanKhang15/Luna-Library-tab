"""Tags URL configuration."""

from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_tags, name='tags-list'),
]
