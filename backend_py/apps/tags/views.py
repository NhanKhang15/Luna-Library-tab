"""Tags views."""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema

from .models import Tag
from .serializers import TagSerializer


@extend_schema(
    responses={200: TagSerializer(many=True)},
    description="Get all tags"
)
@api_view(['GET'])
@permission_classes([AllowAny])
def list_tags(request):
    """Get all available tags."""
    tags = Tag.objects.all().order_by('name')
    serializer = TagSerializer(tags, many=True)
    return Response(serializer.data)
