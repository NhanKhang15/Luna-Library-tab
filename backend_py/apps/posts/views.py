"""
Post views - API endpoints for posts.
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter

from .services import PostService
from .serializers import (
    PostListResponseSerializer,
    PostDetailSerializer,
    LikeToggleResponseSerializer,
    RelatedContentResponseSerializer,
    PostListItemSerializer
)


def get_user_id_from_header(request):
    """Parse X-User-Id header for simulated authentication."""
    user_id = request.headers.get('X-User-Id')
    if user_id:
        try:
            return int(user_id)
        except ValueError:
            pass
    return None


@extend_schema(
    parameters=[
        OpenApiParameter(name='q', type=str, description='Search query'),
        OpenApiParameter(name='sort', type=str, description='Sort by: TRENDING, NEWEST, MOST_VIEWED, MOST_LIKED'),
        OpenApiParameter(name='page', type=int, description='Page number', default=1),
        OpenApiParameter(name='pageSize', type=int, description='Page size', default=10),
        OpenApiParameter(name='premium', type=bool, description='Filter by premium status'),
        OpenApiParameter(name='tag', type=str, description='Filter by tag name'),
    ],
    responses={200: PostListResponseSerializer},
    description="List posts with search, sort, and pagination"
)
@api_view(['GET'])
@permission_classes([AllowAny])
def list_posts(request):
    """List Foundation Posts with search, sort, and pagination."""
    try:
        user_id = get_user_id_from_header(request)
        result = PostService.get_posts(
            q=request.query_params.get('q'),
            sort=request.query_params.get('sort'),
            page=int(request.query_params.get('page', 1)),
            page_size=int(request.query_params.get('pageSize', 10)),
            premium=request.query_params.get('premium'),
            tag_name=request.query_params.get('tag'),
            user_id=user_id
        )
        
        # Serialize items
        items_serializer = PostListItemSerializer(result['items'], many=True)
        response_data = {
            'page': result['page'],
            'pageSize': result['pageSize'],
            'total': result['total'],
            'items': items_serializer.data
        }
        
        return Response(response_data)
    except ValueError as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(
    responses={200: PostDetailSerializer, 404: dict},
    description="Get post detail with atomic view count increment"
)
@api_view(['GET'])
@permission_classes([AllowAny])
def get_post_detail(request, post_id: int):
    """Get Post Detail with atomic view count increment."""
    user_id = get_user_id_from_header(request)
    post = PostService.get_post_detail(post_id, user_id)
    
    if not post:
        return Response(
            {'error': f'Post with id {post_id} not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    serializer = PostDetailSerializer(post)
    return Response(serializer.data)


@extend_schema(
    responses={200: LikeToggleResponseSerializer, 401: dict, 404: dict},
    description="Toggle like on a post (like/unlike). Requires X-User-Id header."
)
@api_view(['POST'])
@permission_classes([AllowAny])
def toggle_like(request, post_id: int):
    """Toggle like on a post (like/unlike)."""
    user_id = get_user_id_from_header(request)
    
    if not user_id:
        return Response(
            {'error': 'X-User-Id header is required'},
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    try:
        result = PostService.toggle_like(post_id, user_id)
        return Response(result)
    except ValueError as e:
        return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


@extend_schema(
    parameters=[
        OpenApiParameter(name='page', type=int, description='Page number', default=1),
        OpenApiParameter(name='pageSize', type=int, description='Page size', default=6),
    ],
    responses={200: RelatedContentResponseSerializer},
    description="Get related content (posts and videos with same categories)"
)
@api_view(['GET'])
@permission_classes([AllowAny])
def get_related_content(request, post_id: int):
    """Get related content (posts and videos with same categories)."""
    result = PostService.get_related_content(
        post_id,
        page=int(request.query_params.get('page', 1)),
        page_size=int(request.query_params.get('pageSize', 6))
    )
    return Response(result)
