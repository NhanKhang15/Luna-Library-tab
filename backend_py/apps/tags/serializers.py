"""Tags serializers."""

from rest_framework import serializers
from .models import Tag, ContentCategory


class TagSerializer(serializers.ModelSerializer):
    """Tag serializer."""
    id = serializers.IntegerField(source='tag_id', read_only=True)
    
    class Meta:
        model = Tag
        fields = ['id', 'name', 'slug']


class CategorySerializer(serializers.ModelSerializer):
    """Category serializer."""
    id = serializers.IntegerField(source='category_id', read_only=True)
    
    class Meta:
        model = ContentCategory
        fields = ['id', 'name', 'slug']
