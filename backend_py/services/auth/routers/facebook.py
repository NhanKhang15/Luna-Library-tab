"""
Facebook Router - POST /auth/facebook

Facebook OAuth authentication.
"""

from fastapi import APIRouter, HTTPException
from ..schemas import FacebookLoginRequest, FacebookLoginResponse, ErrorResponse
from ..services import AuthService

router = APIRouter()


@router.post(
    "/facebook",
    response_model=FacebookLoginResponse,
    responses={
        200: {"description": "Facebook login successful"},
        401: {"model": ErrorResponse, "description": "Invalid Facebook token"},
        409: {"model": ErrorResponse, "description": "Email already registered with local account"}
    },
    summary="Login with Facebook",
    description="""
    Authenticate using Facebook OAuth.
    
    - Verifies Facebook access token
    - Creates new account if user doesn't exist
    - Facebook accounts are auto-verified (no OTP required)
    - Returns isNewUser flag to indicate first-time login
    """
)
def facebook_login(request: FacebookLoginRequest):
    """
    Authenticate with Facebook access token.
    
    - **accessToken**: Facebook access token from Flutter Facebook Auth
    """
    response, error, status_code = AuthService.facebook_login(
        access_token=request.accessToken
    )
    
    if error:
        raise HTTPException(status_code=status_code, detail=error)
    
    return response
