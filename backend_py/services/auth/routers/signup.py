"""
Signup Router - POST /auth/signup

Local user registration.
"""

from fastapi import APIRouter, HTTPException
from ..schemas import SignupRequest, SignupResponse, ErrorResponse
from ..services import AuthService

router = APIRouter()


@router.post(
    "/signup",
    response_model=SignupResponse,
    responses={
        201: {"description": "Account created successfully"},
        409: {"model": ErrorResponse, "description": "Username or email already exists"},
        500: {"model": ErrorResponse, "description": "Server error"}
    },
    summary="Register new local account",
    description="""
    Register a new user account with local authentication.
    
    After signup:
    - AccountVerified = FALSE
    - User must verify using OTP (email or SMS)
    - User cannot login until verified
    """
)
def signup(request: SignupRequest):
    """
    Create a new local user account.
    
    - **username**: Unique username (3-50 chars, alphanumeric + underscore)
    - **password**: Password (min 6 chars)
    - **email**: Optional email address
    - **phoneNumber**: Optional phone number
    """
    response, error, status_code = AuthService.signup(
        username=request.username,
        password=request.password,
        email=request.email,
        phone_number=request.phoneNumber
    )
    
    if error:
        raise HTTPException(status_code=status_code, detail=error)
    
    return response
