"""
Google Router - POST /auth/google

Google OAuth authentication.
"""

from fastapi import APIRouter, HTTPException
from ..schemas import GoogleLoginRequest, GoogleLoginResponse, ErrorResponse
from ..services import AuthService

router = APIRouter()


@router.post(
    "/google",
    response_model=GoogleLoginResponse,
    responses={
        200: {"description": "Google login successful"},
        401: {"model": ErrorResponse, "description": "Invalid Google token"},
        409: {"model": ErrorResponse, "description": "Email already registered with local account"}
    },
    summary="Login with Google",
    description="""
    Authenticate using Google OAuth.
    
    - Verifies Google ID token
    - Creates new account if user doesn't exist
    - Google accounts are auto-verified (no OTP required)
    - Returns isNewUser flag to indicate first-time login
    """
)
def google_login(request: GoogleLoginRequest):
    """
    Authenticate with Google ID token.
    
    - **idToken**: Google ID token from Flutter Google Sign-In
    """
    response, error, status_code = AuthService.google_login(
        id_token=request.idToken
    )
    
    if error:
        raise HTTPException(status_code=status_code, detail=error)
    
    return response
