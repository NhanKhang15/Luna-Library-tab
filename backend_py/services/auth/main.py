"""
FastAPI Auth Service - Main Application

Provides authentication endpoints:
- POST /auth/signup - Local registration
- POST /auth/login - Local login (requires verified account)
- POST /auth/google - Google OAuth login
- POST /auth/otp/request - Request OTP
- POST /auth/otp/verify - Verify OTP

Run with: uvicorn services.auth.main:app --port 8001 --reload
"""

import os
import sys

# Add project root to path for Django imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .routers import signup, login, google, facebook, otp


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler for startup/shutdown."""
    # Startup
    print("🚀 Auth Service starting...")
    print("📍 Endpoints available at /auth/...")
    yield
    # Shutdown
    print("👋 Auth Service shutting down...")


app = FastAPI(
    title="Floria Auth Service",
    description="""
    Authentication API for Floria Flutter App.
    
    ## Features
    - Local signup with OTP verification
    - Local login (username/email/phone + password)
    - Google OAuth login
    - OTP request and verification (email/SMS)
    
    ## Authentication Flows
    
    ### Local Registration
    1. POST /auth/signup → Create account (unverified)
    2. POST /auth/otp/request → Send OTP to email/phone
    3. POST /auth/otp/verify → Verify OTP, mark account verified
    4. POST /auth/login → Login with credentials
    
    ### Google Login
    1. Flutter app gets Google ID token
    2. POST /auth/google → Verify token, auto-create/login user
    """,
    version="1.0.0",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins in development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(signup.router, prefix="/auth", tags=["Authentication"])
app.include_router(login.router, prefix="/auth", tags=["Authentication"])
app.include_router(google.router, prefix="/auth", tags=["Social Auth"])
app.include_router(facebook.router, prefix="/auth", tags=["Social Auth"])
app.include_router(otp.router, prefix="/auth", tags=["OTP Verification"])


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint."""
    return {
        "service": "Floria Auth Service",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "database": "connected",
        "services": {
            "auth": "ok",
            "otp": "ok"
        }
    }
