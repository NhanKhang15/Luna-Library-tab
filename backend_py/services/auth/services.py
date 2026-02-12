"""
Auth Service - Business logic for authentication operations.

Handles:
- Local signup with password hashing
- Local login with verification check
- Google OAuth token verification
- User lookup and creation
"""

import os
import bcrypt
import logging
from typing import Tuple, Optional, Dict, Any
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Setup Django
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User
from apps.otp.services import OTPService, EmailOTPSender, SMSOTPSender
from .jwt_utils import create_tokens_for_user

logger = logging.getLogger(__name__)


class AuthService:
    """Authentication service for signup, login, and social auth."""
    
    # ============== PASSWORD HANDLING ==============
    
    @staticmethod
    def hash_password(password: str) -> bytes:
        """Hash password using BCrypt, return as bytes for VARBINARY storage."""
        salt = bcrypt.gensalt(rounds=12)
        return bcrypt.hashpw(password.encode('utf-8'), salt)
    
    @staticmethod
    def verify_password(password: str, hashed: bytes) -> bool:
        """Verify password against BCrypt hash."""
        try:
            return bcrypt.checkpw(password.encode('utf-8'), bytes(hashed))
        except Exception as e:
            logger.error(f"Password verification error: {e}")
            return False
    
    # ============== LOCAL SIGNUP ==============
    
    @classmethod
    def signup(
        cls,
        username: str,
        password: str,
        email: Optional[str] = None,
        phone_number: Optional[str] = None
    ) -> Tuple[Optional[Dict], Optional[str], int]:
        """
        Register a new local user.
        
        Returns: (response_data, error_message, status_code)
        """
        logger.info(f"Signup attempt for username: {username}")
        
        # Check if username exists
        if User.objects.filter(username__iexact=username).exists():
            return None, "Username already taken", 409
        
        # Check if email exists (if provided)
        if email and User.objects.filter(email__iexact=email).exists():
            return None, "Email already registered", 409
        
        # Hash password
        password_hash = cls.hash_password(password)
        
        # Create user
        try:
            user = User.objects.create(
                username=username,
                email=email.lower().strip() if email else None,
                phone_number=phone_number.strip() if phone_number else None,
                password_hashed=password_hash,
                auth_primary=User.AUTH_LOCAL,
                status=User.STATUS_ACTIVE,
                account_verified=False,  # Requires OTP verification
                profile_completed=False
            )
            
            logger.info(f"User created: {user.user_id}")
            
            return {
                'success': True,
                'userId': user.user_id,
                'message': 'Account created successfully. Please verify your account using OTP.'
            }, None, 201
            
        except Exception as e:
            logger.error(f"Signup error: {e}")
            return None, "Failed to create account", 500
    
    # ============== LOCAL LOGIN ==============
    
    @classmethod
    def login(
        cls,
        identifier: str,
        password: str
    ) -> Tuple[Optional[Dict], Optional[str], int]:
        """
        Authenticate local user.
        
        identifier can be: username, email, or phone
        
        Returns: (response_data, error_message, status_code)
        """
        logger.info(f"Login attempt for: {identifier}")
        
        # Find user by username, email, or phone
        user = None
        try:
            user = User.objects.get(username__iexact=identifier)
        except User.DoesNotExist:
            try:
                user = User.objects.get(email__iexact=identifier)
            except User.DoesNotExist:
                try:
                    user = User.objects.get(phone_number=identifier)
                except User.DoesNotExist:
                    pass
        
        if not user:
            logger.warning(f"User not found: {identifier}")
            return None, "Invalid credentials", 401
        
        # Check if local auth
        if not user.is_local_auth:
            return None, f"Please login with {user.auth_primary}", 400
        
        # Check password
        if not user.password_hashed or not cls.verify_password(password, user.password_hashed):
            logger.warning(f"Invalid password for user: {user.user_id}")
            return None, "Invalid credentials", 401
        
        # Check account status
        if user.status == User.STATUS_DISABLED:
            return None, "Account is disabled", 403
        if user.status == User.STATUS_BANNED:
            return None, "Account is banned", 403
        
        # Check verification (required for local auth)
        if not user.account_verified:
            return None, "Account not verified. Please verify with OTP.", 403
        
        # Generate tokens
        tokens = create_tokens_for_user(
            user_id=user.user_id,
            username=user.username,
            email=user.email
        )
        
        logger.info(f"Login successful for user: {user.user_id}")
        
        return {
            **tokens,
            'user': cls._user_to_dict(user)
        }, None, 200
    
    # ============== GOOGLE LOGIN ==============
    
    @classmethod
    def google_login(cls, id_token: str) -> Tuple[Optional[Dict], Optional[str], int]:
        """
        Authenticate user with Google ID token.
        
        Returns: (response_data, error_message, status_code)
        """
        # Verify Google ID token
        google_user = cls._verify_google_token(id_token)
        if not google_user:
            return None, "Invalid Google token", 401
        
        google_uid = google_user['sub']
        email = google_user.get('email')
        name = google_user.get('name', email.split('@')[0] if email else 'User')
        
        logger.info(f"Google login for: {email}")
        
        # Find existing user by Google UID
        try:
            user = User.objects.get(social_provider=User.SOCIAL_GOOGLE, social_uid=google_uid)
            is_new_user = False
            logger.info(f"Existing Google user found: {user.user_id}")
        except User.DoesNotExist:
            # Check if email exists with local auth
            if email:
                try:
                    existing = User.objects.get(email__iexact=email)
                    if existing.is_local_auth:
                        return None, "Email already registered with local account", 409
                except User.DoesNotExist:
                    pass
            
            # Create new user
            user = User.objects.create(
                username=cls._generate_unique_username(name),
                email=email,
                social_provider=User.SOCIAL_GOOGLE,
                social_uid=google_uid,
                auth_primary=User.AUTH_GOOGLE,
                status=User.STATUS_ACTIVE,
                account_verified=True,  # Google accounts are auto-verified
                profile_completed=False
            )
            is_new_user = True
            logger.info(f"New Google user created: {user.user_id}")
        
        # Generate tokens
        tokens = create_tokens_for_user(
            user_id=user.user_id,
            username=user.username,
            email=user.email
        )
        
        return {
            **tokens,
            'user': cls._user_to_dict(user),
            'isNewUser': is_new_user
        }, None, 200
    
    # ============== FACEBOOK LOGIN ==============
    
    @classmethod
    def facebook_login(cls, access_token: str) -> Tuple[Optional[Dict], Optional[str], int]:
        """
        Authenticate user with Facebook access token.
        
        Returns: (response_data, error_message, status_code)
        """
        # Verify Facebook access token
        facebook_user = cls._verify_facebook_token(access_token)
        if not facebook_user:
            return None, "Invalid Facebook token", 401
        
        facebook_uid = facebook_user['id']
        email = facebook_user.get('email')
        name = facebook_user.get('name', email.split('@')[0] if email else 'User')
        
        logger.info(f"Facebook login for: {email}")
        
        # Find existing user by Facebook UID
        try:
            user = User.objects.get(social_provider=User.SOCIAL_FACEBOOK, social_uid=facebook_uid)
            is_new_user = False
            logger.info(f"Existing Facebook user found: {user.user_id}")
        except User.DoesNotExist:
            # Check if email exists with local auth
            if email:
                try:
                    existing = User.objects.get(email__iexact=email)
                    if existing.is_local_auth:
                        return None, "Email already registered with local account", 409
                except User.DoesNotExist:
                    pass
            
            # Create new user
            user = User.objects.create(
                username=cls._generate_unique_username(name),
                email=email,
                social_provider=User.SOCIAL_FACEBOOK,
                social_uid=facebook_uid,
                auth_primary=User.AUTH_FACEBOOK,
                status=User.STATUS_ACTIVE,
                account_verified=True,  # Facebook accounts are auto-verified
                profile_completed=False
            )
            is_new_user = True
            logger.info(f"New Facebook user created: {user.user_id}")
        
        # Generate tokens
        tokens = create_tokens_for_user(
            user_id=user.user_id,
            username=user.username,
            email=user.email
        )
        
        return {
            **tokens,
            'user': cls._user_to_dict(user),
            'isNewUser': is_new_user
        }, None, 200
    
    @staticmethod
    def _verify_facebook_token(access_token: str) -> Optional[Dict]:
        """
        Verify Facebook access token by calling Graph API.
        
        Returns user info or None if invalid.
        """
        try:
            import requests
            
            # Call Facebook Graph API to verify token and get user info
            url = f"https://graph.facebook.com/me?fields=id,name,email&access_token={access_token}"
            response = requests.get(url, timeout=10)
            
            if response.status_code != 200:
                logger.error(f"Facebook token verification failed: {response.text}")
                return None
            
            user_data = response.json()
            
            if 'error' in user_data:
                logger.error(f"Facebook API error: {user_data['error']}")
                return None
            
            return user_data
            
        except Exception as e:
            logger.error(f"Facebook token verification failed: {e}")
            return None
    
    @staticmethod
    def _verify_google_token(id_token: str) -> Optional[Dict]:
        """
        Verify Google ID token using google-auth library.
        
        Returns decoded token payload or None if invalid.
        """
        try:
            from google.oauth2 import id_token as google_id_token
            from google.auth.transport import requests
            
            client_id = os.getenv('GOOGLE_CLIENT_ID')
            if not client_id:
                logger.error("GOOGLE_CLIENT_ID not configured")
                return None
            
            client_ids = [cid.strip() for cid in client_id.split(',')]
            
            # Verify the token
            idinfo = google_id_token.verify_oauth2_token(
                id_token,
                requests.Request(),
                audience=client_ids
            )
            
            return idinfo
            
        except Exception as e:
            logger.error(f"Google token verification failed: {e}")
            return None
    
    @staticmethod
    def _generate_unique_username(name: str) -> str:
        """Generate unique username from display name."""
        import random
        import string
        
        # Clean name
        base = ''.join(c for c in name.lower() if c.isalnum())[:15]
        if not base:
            base = 'user'
        
        username = base
        suffix_length = 4
        
        while User.objects.filter(username__iexact=username).exists():
            suffix = ''.join(random.choices(string.digits, k=suffix_length))
            username = f"{base}{suffix}"
        
        return username
    
    @staticmethod
    def _user_to_dict(user: User) -> Dict[str, Any]:
        """Convert User model to response dict."""
        return {
            'id': user.user_id,
            'username': user.username,
            'email': user.email,
            'phoneNumber': user.phone_number,
            'authPrimary': user.auth_primary,
            'status': user.status,
            'profileCompleted': user.profile_completed,
            'accountVerified': user.account_verified
        }
    
    # ============== OTP OPERATIONS ==============
    
    @classmethod
    def request_otp(
        cls,
        user_id: int,
        method: str
    ) -> Tuple[Optional[Dict], Optional[str], int]:
        """
        Request OTP for account verification.
        
        method: 'email' or 'sms'
        
        Returns: (response_data, error_message, status_code)
        """
        # Get user
        try:
            user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return None, "User not found", 404
        
        # Check if already verified
        if user.account_verified:
            return None, "Account already verified", 400
        
        # Determine target
        if method == 'email':
            if not user.email:
                return None, "No email address on file", 400
            target = user.email
        else:  # sms
            if not user.phone_number:
                return None, "No phone number on file", 400
            target = user.phone_number
        
        # Create OTP
        otp, error = OTPService.create_otp_request(user_id, method, target)
        if error:
            return None, error, 429  # Rate limited
        
        # Send OTP
        if method == 'email':
            success, message = EmailOTPSender.send(target, otp, user.username)
        else:
            success, message = SMSOTPSender.send(target, otp)
        
        if not success:
            return None, "Failed to send OTP", 500
        
        return {'success': True, 'message': message}, None, 200
    
    @classmethod
    def verify_otp(cls, user_id: int, otp: str) -> Tuple[Optional[Dict], Optional[str], int]:
        """
        Verify OTP and mark account as verified.
        
        Returns: (response_data, error_message, status_code)
        """
        # Verify OTP
        success, message = OTPService.verify_otp(user_id, otp)
        
        if not success:
            return None, message, 400
        
        # Mark user as verified
        try:
            user = User.objects.get(user_id=user_id)
            user.account_verified = True
            user.save(update_fields=['account_verified'])
            
            logger.info(f"Account verified for user: {user_id}")
            
            return {
                'success': True,
                'accountVerified': True,
                'message': 'Account verified successfully. You can now login.'
            }, None, 200
            
        except User.DoesNotExist:
            return None, "User not found", 404
