"""
Authentication views - API endpoints for login, signup, and user info.
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import AccessToken
from drf_spectacular.utils import extend_schema, OpenApiResponse

from .serializers import (
    LoginRequestSerializer,
    LoginResponseSerializer,
    SignupRequestSerializer,
    SignupResponseSerializer,
    UserSerializer,
    ErrorResponseSerializer
)
from .services import AuthService


@extend_schema(
    request=LoginRequestSerializer,
    responses={
        200: LoginResponseSerializer,
        400: ErrorResponseSerializer,
        401: ErrorResponseSerializer,
        403: ErrorResponseSerializer,
    },
    description="Authenticate user with email and password"
)
@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """
    Authenticate user with email and password.
    Returns JWT token and user info on success.
    """
    serializer = LoginRequestSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {'error': 'Invalid request payload'},
            status=status.HTTP_400_BAD_REQUEST
        )

    email_or_username = serializer.validated_data['emailOrUsername']
    password = serializer.validated_data['password']

    response_data, error_message, status_code = AuthService.login(
        email_or_username,
        password
    )

    if error_message:
        return Response({'error': error_message}, status=status_code)

    return Response(response_data, status=status.HTTP_200_OK)


@extend_schema(
    request=SignupRequestSerializer,
    responses={
        201: SignupResponseSerializer,
        400: ErrorResponseSerializer,
        409: ErrorResponseSerializer,
    },
    description="Register a new user account"
)
@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    """
    Register a new user account.
    Returns registered user info on success.
    """
    serializer = SignupRequestSerializer(data=request.data)
    if not serializer.is_valid():
        errors = serializer.errors
        first_error = next(iter(errors.values()))[0] if errors else 'Invalid request'
        return Response({'error': str(first_error)}, status=status.HTTP_400_BAD_REQUEST)

    response_data, error_message, status_code = AuthService.register(
        email=serializer.validated_data['email'],
        password=serializer.validated_data['password'],
        name=serializer.validated_data['name'],
        phone=serializer.validated_data.get('phone')
    )

    if error_message:
        return Response({'error': error_message}, status=status_code)

    return Response(response_data, status=status.HTTP_201_CREATED)


@extend_schema(
    responses={
        200: UserSerializer,
        401: ErrorResponseSerializer,
    },
    description="Get current authenticated user info"
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    """
    Get current authenticated user info (protected endpoint).
    Requires valid JWT Bearer token.
    """
    # Extract user info from JWT token
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if not auth_header.startswith('Bearer '):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    token_str = auth_header.split(' ')[1]
    
    try:
        token = AccessToken(token_str)
        return Response({
            'id': token.get('sub'),
            'email': token.get('email', ''),
            'name': token.get('name', ''),
            'role': token.get('role', 'user')
        })
    except Exception:
        return Response({'error': 'Invalid token'}, status=status.HTTP_401_UNAUTHORIZED)
