"""
OTP Router - /auth/otp/request, /auth/otp/verify

OTP-based account verification.
"""

from fastapi import APIRouter, HTTPException
from ..schemas import OTPRequestRequest, OTPVerifyRequest, OTPRequestResponse, OTPVerifyResponse, ErrorResponse
from ..services import AuthService

router = APIRouter()


@router.post(
    "/otp/request",
    response_model=OTPRequestResponse,
    responses={
        200: {"description": "OTP sent successfully"},
        400: {"model": ErrorResponse, "description": "Invalid request"},
        404: {"model": ErrorResponse, "description": "User not found"},
        429: {"model": ErrorResponse, "description": "Too many requests"}
    },
    summary="Request OTP",
    description="""
    Request OTP for account verification.
    
    Methods:
    - **email**: Send OTP to registered email
    - **sms**: Send OTP to registered phone number
    
    Rate limit: 5 requests per hour
    OTP expires in 5 minutes
    """
)
def request_otp(request: OTPRequestRequest):
    """
    Request OTP to verify account.
    
    - **userId**: User ID from signup response
    - **method**: 'email' or 'sms'
    """
    response, error, status_code = AuthService.request_otp(
        user_id=request.userId,
        method=request.method
    )
    
    if error:
        raise HTTPException(status_code=status_code, detail=error)
    
    return response


@router.post(
    "/otp/verify",
    response_model=OTPVerifyResponse,
    responses={
        200: {"description": "OTP verified successfully"},
        400: {"model": ErrorResponse, "description": "Invalid or expired OTP"},
        404: {"model": ErrorResponse, "description": "User not found"}
    },
    summary="Verify OTP",
    description="""
    Verify OTP and mark account as verified.
    
    After successful verification:
    - AccountVerified = TRUE
    - User can now login
    """
)
def verify_otp(request: OTPVerifyRequest):
    """
    Verify OTP code.
    
    - **userId**: User ID
    - **otp**: 6-digit OTP code
    """
    response, error, status_code = AuthService.verify_otp(
        user_id=request.userId,
        otp=request.otp
    )
    
    if error:
        raise HTTPException(status_code=status_code, detail=error)
    
    return response
