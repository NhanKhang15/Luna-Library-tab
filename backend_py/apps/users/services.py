"""
Authentication service - Business logic for auth operations.
"""

import bcrypt
import logging
from datetime import datetime, timedelta
from typing import Optional, Tuple
from django.conf import settings
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User

logger = logging.getLogger(__name__)


class AuthService:
    """Authentication service with JWT and BCrypt."""

    @staticmethod
    def generate_tokens(user: User) -> Tuple[str, str, int]:
        """
        Generate JWT access and refresh tokens.
        Returns: (access_token, refresh_token, expires_in_seconds)
        """
        # Create custom token with user claims
        refresh = RefreshToken()
        refresh['sub'] = user.user_id
        refresh['email'] = user.email
        refresh['name'] = user.name
        refresh['role'] = user.role

        access_token = str(refresh.access_token)
        refresh_token = str(refresh)
        expires_in = int(settings.SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'].total_seconds())

        return access_token, refresh_token, expires_in

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify password against BCrypt hash."""
        try:
            return bcrypt.checkpw(
                plain_password.encode('utf-8'),
                hashed_password.encode('utf-8')
            )
        except Exception as e:
            logger.error(f"BCrypt verification error: {e}")
            return False

    @staticmethod
    def hash_password(password: str) -> str:
        """Hash password using BCrypt."""
        salt = bcrypt.gensalt(rounds=12)
        return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

    @classmethod
    def login(cls, email_or_username: str, password: str) -> Tuple[Optional[dict], Optional[str], int]:
        """
        Authenticate user with email and password.
        Returns: (response_data, error_message, status_code)
        """
        logger.info(f"Login attempt for: {email_or_username}")

        # Find user by email
        try:
            user = User.objects.get(email__iexact=email_or_username)
        except User.DoesNotExist:
            logger.warning(f"Login failed: User not found for {email_or_username}")
            return None, "Invalid email or password", 401

        # Check if account is active
        if not user.active:
            logger.warning(f"Login failed: Account disabled for user {user.user_id}")
            return None, "Account is disabled. Please contact support.", 403

        # Verify password
        if not cls.verify_password(password, user.password_hashed):
            logger.warning(f"Login failed: Invalid password for user {user.user_id}")
            return None, "Invalid email or password", 401

        # Generate tokens
        access_token, refresh_token, expires_in = cls.generate_tokens(user)

        logger.info(f"Login successful for user {user.user_id}")

        return {
            'accessToken': access_token,
            'expiresIn': expires_in,
            'refreshToken': refresh_token,
            'user': {
                'id': user.user_id,
                'email': user.email,
                'name': user.name,
                'role': user.role
            }
        }, None, 200

    @classmethod
    def register(cls, email: str, password: str, name: str, phone: Optional[str] = None) -> Tuple[Optional[dict], Optional[str], int]:
        """
        Register a new user.
        Returns: (response_data, error_message, status_code)
        """
        logger.info(f"Registration attempt for: {email}")

        # Check if email exists
        if User.objects.filter(email__iexact=email).exists():
            logger.warning(f"Registration failed: Email already exists - {email}")
            return None, "An account with this email already exists", 409

        # Hash password
        password_hash = cls.hash_password(password)

        # Create user
        try:
            user = User.objects.create(
                email=email.strip().lower(),
                password_hashed=password_hash,
                name=name.strip(),
                phone=phone.strip() if phone else None,
                active=True,
                role='user',
                created_at=datetime.now()
            )

            logger.info(f"Registration successful for user {user.user_id} - {email}")

            return {
                'success': True,
                'message': 'Registration successful. You can now login with your credentials.',
                'user': {
                    'id': user.user_id,
                    'email': user.email,
                    'name': user.name,
                    'role': user.role
                }
            }, None, 201

        except Exception as e:
            logger.error(f"Database error during registration for {email}: {e}")
            return None, "Failed to create account. Please try again.", 400
