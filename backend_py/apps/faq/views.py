"""FAQ views."""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter

from .models import FAQ
from .serializers import FAQItemSerializer, FAQListResponseSerializer


CATEGORY_MAP = {
    'tam-ly': 'tam-ly',
    'sinh-hoc': 'sinh-hoc',
    'phap-ly': 'phap-ly',
}


@extend_schema(
    parameters=[
        OpenApiParameter(
            name='category',
            type=str,
            description='FAQ category slug: tam-ly, sinh-hoc, phap-ly',
            required=False,
        ),
    ],
    responses={200: FAQListResponseSerializer},
    description="List FAQs, optionally filtered by category",
)
@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def list_faqs(request):
    """List FAQs with optional category filter."""
    category = request.query_params.get('category', '').strip()

    qs = FAQ.objects.select_related('expert', 'source_post').prefetch_related('tags')

    if category and category in CATEGORY_MAP:
        qs = qs.filter(category=category)

    qs = qs.order_by('faq_id')

    serializer = FAQItemSerializer(qs, many=True)
    return Response({
        'category': category or 'all',
        'items': serializer.data,
    })
