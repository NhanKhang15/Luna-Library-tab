"""
JWT Utilities - Shared JWT logic for Django and FastAPI.

Uses the same secret key and algorithm as Django REST framework SimpleJWT
to ensure tokens are interchangeable between Django and FastAPI.
"""

import os
import jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from dotenv import load_dotenv

load_dotenv()


class JWTConfig:
    """JWT configuration matching Django SimpleJWT."""
    SECRET_KEY = os.getenv('JWT_SECRET_KEY', os.getenv('SECRET_KEY', 'dev-secret-key'))
    ALGORITHM = 'HS256'
    ACCESS_TOKEN_LIFETIME_MINUTES = int(os.getenv('JWT_ACCESS_TOKEN_LIFETIME', 60))
    REFRESH_TOKEN_LIFETIME_MINUTES = int(os.getenv('JWT_REFRESH_TOKEN_LIFETIME', 10080))


def create_access_token(
    user_id: int,
    username: str,
    email: Optional[str] = None,
    extra_claims: Optional[Dict[str, Any]] = None
) -> str:
    """
    Create a JWT access token.
    
    Args:
        user_id: User's ID
        username: Username
        email: Optional email
        extra_claims: Optional additional claims
    
    Returns:
        JWT access token string
    """
    now = datetime.utcnow()
    expire = now + timedelta(minutes=JWTConfig.ACCESS_TOKEN_LIFETIME_MINUTES)
    
    payload = {
        'sub': str(user_id),
        'username': username,
        'email': email,
        'iat': now,
        'exp': expire,
        'token_type': 'access'
    }
    
    if extra_claims:
        payload.update(extra_claims)
    
    return jwt.encode(payload, JWTConfig.SECRET_KEY, algorithm=JWTConfig.ALGORITHM)


def create_refresh_token(user_id: int) -> str:
    """
    Create a JWT refresh token.
    
    Args:
        user_id: User's ID
    
    Returns:
        JWT refresh token string
    """
    now = datetime.utcnow()
    expire = now + timedelta(minutes=JWTConfig.REFRESH_TOKEN_LIFETIME_MINUTES)
    
    payload = {
        'sub': str(user_id),
        'iat': now,
        'exp': expire,
        'token_type': 'refresh'
    }
    
    return jwt.encode(payload, JWTConfig.SECRET_KEY, algorithm=JWTConfig.ALGORITHM)


def decode_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Decode and validate a JWT token.
    
    Args:
        token: JWT token string
    
    Returns:
        Decoded payload or None if invalid
    """
    try:
        payload = jwt.decode(
            token,
            JWTConfig.SECRET_KEY,
            algorithms=[JWTConfig.ALGORITHM]
        )
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def create_tokens_for_user(
    user_id: int,
    username: str,
    email: Optional[str] = None,
    extra_claims: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Create both access and refresh tokens for a user.
    
    Returns dict with:
        - accessToken: JWT access token
        - refreshToken: JWT refresh token
        - expiresIn: Access token lifetime in seconds
    """
    access_token = create_access_token(user_id, username, email, extra_claims)
    refresh_token = create_refresh_token(user_id)
    
    return {
        'accessToken': access_token,
        'refreshToken': refresh_token,
        'expiresIn': JWTConfig.ACCESS_TOKEN_LIFETIME_MINUTES * 60
    }
