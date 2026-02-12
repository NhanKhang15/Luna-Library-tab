"""
User serializers for API endpoints.
"""

from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Basic user info serializer."""
    id = serializers.IntegerField(source='user_id', read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'email', 'name', 'role']


class LoginRequestSerializer(serializers.Serializer):
    """Login request payload."""
    emailOrUsername = serializers.CharField(
        max_length=255,
        help_text="Email address"
    )
    password = serializers.CharField(
        max_length=128,
        write_only=True,
        style={'input_type': 'password'}
    )


class LoginResponseSerializer(serializers.Serializer):
    """Login response payload."""
    accessToken = serializers.CharField()
    expiresIn = serializers.IntegerField()
    refreshToken = serializers.CharField(allow_null=True, required=False)
    user = UserSerializer()


class SignupRequestSerializer(serializers.Serializer):
    """Signup request payload."""
    email = serializers.EmailField(max_length=255)
    password = serializers.CharField(
        max_length=128,
        min_length=6,
        write_only=True,
        style={'input_type': 'password'}
    )
    name = serializers.CharField(max_length=100)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_email(self, value):
        """Check if email already exists."""
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("An account with this email already exists")
        return value.lower().strip()

    def validate_name(self, value):
        return value.strip()


class SignupResponseSerializer(serializers.Serializer):
    """Signup response payload."""
    success = serializers.BooleanField()
    message = serializers.CharField()
    user = UserSerializer()


class ErrorResponseSerializer(serializers.Serializer):
    """Standard error response."""
    error = serializers.CharField()
