"""
Login Router - POST /auth/login

Local user authentication.
"""

from fastapi import APIRouter, HTTPException
from ..schemas import LoginRequest, LoginResponse, ErrorResponse
from ..services import AuthService

router = APIRouter()


@router.post(
    "/login",
    response_model=LoginResponse,
    responses={
        200: {"description": "Login successful"},
        401: {"model": ErrorResponse, "description": "Invalid credentials"},
        403: {"model": ErrorResponse, "description": "Account not verified or disabled"}
    },
    summary="Login with local account",
    description="""
    Authenticate a local user and receive JWT tokens.
    
    Requirements:
    - Account must be verified (AccountVerified = TRUE)
    - Account must be active (Status = 'active')
    
    Identifier can be:
    - Username
    - Email address
    - Phone number
    """
)
def login(request: LoginRequest):
    """
    Authenticate user and return JWT tokens.
    
    - **identifier**: Username, email, or phone number
    - **password**: Account password
    """
    response, error, status_code = AuthService.login(
        identifier=request.identifier,
        password=request.password
    )
    
    if error:
        raise HTTPException(status_code=status_code, detail=error)
    
    return response
