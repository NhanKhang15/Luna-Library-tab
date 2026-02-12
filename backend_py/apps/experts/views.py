"""
Expert views - API endpoints for experts.
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter

from .services import ExpertService
from .serializers import ExpertListSerializer, ExpertDetailSerializer, ExpertReviewSerializer


@extend_schema(
    parameters=[
        OpenApiParameter(name='q', type=str, description='Search by name'),
        OpenApiParameter(name='page', type=int, description='Page number', default=1),
        OpenApiParameter(name='pageSize', type=int, description='Page size', default=10),
    ],
    responses={200: dict},
    description="List experts with search and pagination",
)
@api_view(['GET'])
@permission_classes([AllowAny])
def list_experts(request):
    """List experts with optional search and pagination."""
    try:
        result = ExpertService.get_experts(
            q=request.query_params.get('q'),
            page=int(request.query_params.get('page', 1)),
            page_size=int(request.query_params.get('pageSize', 10)),
        )

        serializer = ExpertListSerializer(result['items'], many=True)
        return Response({
            'page': result['page'],
            'pageSize': result['pageSize'],
            'total': result['total'],
            'items': serializer.data,
        })
    except ValueError as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(
    responses={200: ExpertDetailSerializer, 404: dict},
    description="Get expert detail by ID",
)
@api_view(['GET'])
@permission_classes([AllowAny])
def get_expert_detail(request, expert_id: int):
    """Get single expert detail."""
    expert = ExpertService.get_expert_detail(expert_id)

    if not expert:
        return Response(
            {'error': f'Expert with id {expert_id} not found'},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = ExpertDetailSerializer(expert)
    return Response(serializer.data)


@extend_schema(
    parameters=[
        OpenApiParameter(name='page', type=int, description='Page number', default=1),
        OpenApiParameter(name='pageSize', type=int, description='Page size', default=10),
    ],
    responses={200: dict},
    description="Get paginated reviews for an expert",
)
@api_view(['GET'])
@permission_classes([AllowAny])
def get_expert_reviews(request, expert_id: int):
    """Get paginated reviews for an expert."""
    try:
        result = ExpertService.get_expert_reviews(
            expert_id=expert_id,
            page=int(request.query_params.get('page', 1)),
            page_size=int(request.query_params.get('pageSize', 10)),
        )

        serializer = ExpertReviewSerializer(result['items'], many=True)
        return Response({
            'page': result['page'],
            'pageSize': result['pageSize'],
            'total': result['total'],
            'items': serializer.data,
        })
    except ValueError as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
