"""
Pydantic schemas for FastAPI auth endpoints.
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
import re


# ============== REQUEST SCHEMAS ==============

class SignupRequest(BaseModel):
    """Local signup request."""
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=128)
    email: Optional[str] = Field(None, max_length=100)
    phoneNumber: Optional[str] = Field(None, max_length=20)
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v):
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username can only contain letters, numbers, and underscores')
        return v
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v):
        if v and not re.match(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', v):
            raise ValueError('Invalid email format')
        return v.lower() if v else None
    
    @field_validator('phoneNumber')
    @classmethod
    def validate_phone(cls, v):
        if v and not re.match(r'^\+?[0-9]{8,15}$', v):
            raise ValueError('Invalid phone number format (8-15 digits)')
        return v


class LoginRequest(BaseModel):
    """Local login request."""
    identifier: str = Field(..., description="Username, email, or phone")
    password: str = Field(..., min_length=1)


class GoogleLoginRequest(BaseModel):
    """Google OAuth login request."""
    idToken: str = Field(..., description="Google ID token from Flutter")


class FacebookLoginRequest(BaseModel):
    """Facebook OAuth login request."""
    accessToken: str = Field(..., description="Facebook access token from Flutter")


class OTPRequestRequest(BaseModel):
    """OTP request payload."""
    userId: int = Field(..., gt=0)
    method: str = Field(..., pattern='^(email|sms)$')


class OTPVerifyRequest(BaseModel):
    """OTP verification payload."""
    userId: int = Field(..., gt=0)
    otp: str = Field(..., min_length=6, max_length=6)
    
    @field_validator('otp')
    @classmethod
    def validate_otp(cls, v):
        if not v.isdigit():
            raise ValueError('OTP must contain only digits')
        return v


# ============== RESPONSE SCHEMAS ==============

class UserResponse(BaseModel):
    """User info in responses."""
    id: int
    username: str
    email: Optional[str]
    phoneNumber: Optional[str]
    authPrimary: str
    status: str
    profileCompleted: bool
    accountVerified: bool


class SignupResponse(BaseModel):
    """Signup response."""
    success: bool
    userId: int
    message: str


class LoginResponse(BaseModel):
    """Login response with tokens."""
    accessToken: str
    refreshToken: str
    expiresIn: int
    user: UserResponse


class GoogleLoginResponse(BaseModel):
    """Google login response."""
    accessToken: str
    refreshToken: str
    expiresIn: int
    user: UserResponse
    isNewUser: bool


class FacebookLoginResponse(BaseModel):
    """Facebook login response."""
    accessToken: str
    refreshToken: str
    expiresIn: int
    user: UserResponse
    isNewUser: bool


class OTPRequestResponse(BaseModel):
    """OTP request response."""
    success: bool
    message: str


class OTPVerifyResponse(BaseModel):
    """OTP verification response."""
    success: bool
    accountVerified: bool
    message: str


class ErrorResponse(BaseModel):
    """Error response."""
    error: str
    details: Optional[str] = None
