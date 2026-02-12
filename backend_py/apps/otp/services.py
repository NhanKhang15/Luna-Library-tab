"""
OTP Service - Business logic for OTP generation, hashing, verification, and delivery.
"""

import hashlib
import secrets
import logging
from typing import Tuple, Optional
from django.utils import timezone
from .models import OTPRequest

logger = logging.getLogger(__name__)


class OTPService:
    """Service for OTP operations."""
    
    OTP_LENGTH = 6
    OTP_EXPIRY_MINUTES = 5
    MAX_REQUESTS_PER_HOUR = 5
    
    @staticmethod
    def generate_otp() -> str:
        """Generate a secure 6-digit numeric OTP."""
        # Generate cryptographically secure random digits
        return ''.join(str(secrets.randbelow(10)) for _ in range(OTPService.OTP_LENGTH))
    
    @staticmethod
    def hash_otp(otp: str, salt: str = '') -> str:
        """Hash OTP using SHA-256 with optional salt."""
        combined = f"{otp}{salt}"
        return hashlib.sha256(combined.encode()).hexdigest()
    
    @classmethod
    def create_otp_request(
        cls,
        user_id: int,
        method: str,
        target: str
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Create a new OTP request.
        
        Returns: (otp, error_message)
        - otp: Plain OTP to send (None if error)
        - error_message: Error message (None if success)
        """
        # Check rate limiting
        recent_requests = OTPRequest.objects.filter(
            user_id=user_id,
            created_at__gte=timezone.now() - timezone.timedelta(hours=1)
        ).count()
        
        # Rate limiting disabled for development
        # if recent_requests >= cls.MAX_REQUESTS_PER_HOUR:
        #     logger.warning(f"Rate limit exceeded for user {user_id}")
        #     return None, "Too many OTP requests. Please try again later."
        
        # Invalidate previous unverified OTPs
        OTPRequest.objects.filter(
            user_id=user_id,
            verified=False
        ).update(verified=True)  # Mark as used
        
        # Generate new OTP
        otp = cls.generate_otp()
        otp_hash = cls.hash_otp(otp, str(user_id))
        
        # Create request
        otp_request = OTPRequest.objects.create(
            user_id=user_id,
            otp_hash=otp_hash,
            method=method,
            target=target,
            expires_at=OTPRequest.get_expiry_time(cls.OTP_EXPIRY_MINUTES)
        )
        
        logger.info(f"Created OTP request {otp_request.id} for user {user_id} via {method}")
        
        return otp, None
    
    @classmethod
    def verify_otp(cls, user_id: int, otp: str) -> Tuple[bool, str]:
        """
        Verify OTP for a user.
        
        Returns: (success, message)
        """
        # Find latest unverified OTP
        try:
            otp_request = OTPRequest.objects.filter(
                user_id=user_id,
                verified=False
            ).latest('created_at')
        except OTPRequest.DoesNotExist:
            logger.warning(f"No pending OTP for user {user_id}")
            return False, "No pending OTP request. Please request a new one."
        
        # Check if expired
        if otp_request.is_expired:
            logger.warning(f"OTP expired for user {user_id}")
            return False, "OTP has expired. Please request a new one."
        
        # Check attempts
        if not otp_request.can_attempt:
            logger.warning(f"Max attempts exceeded for user {user_id}")
            return False, "Too many failed attempts. Please request a new OTP."
        
        # Increment attempts
        otp_request.attempts += 1
        otp_request.save(update_fields=['attempts'])
        
        # Verify hash
        otp_hash = cls.hash_otp(otp, str(user_id))
        if otp_hash != otp_request.otp_hash:
            logger.warning(f"Invalid OTP attempt for user {user_id}")
            remaining = 5 - otp_request.attempts
            return False, f"Invalid OTP. {remaining} attempts remaining."
        
        # Mark as verified
        otp_request.verified = True
        otp_request.save(update_fields=['verified'])
        
        logger.info(f"OTP verified successfully for user {user_id}")
        return True, "OTP verified successfully."
    
    @staticmethod
    def mask_email(email: str) -> str:
        """Mask email for display (e.g., k***@gmail.com)."""
        if not email or '@' not in email:
            return email
        local, domain = email.split('@', 1)
        if len(local) <= 2:
            masked = local[0] + '***'
        else:
            masked = local[0] + '***' + local[-1]
        return f"{masked}@{domain}"
    
    @staticmethod
    def mask_phone(phone: str) -> str:
        """Mask phone for display (e.g., +84***4567)."""
        if not phone or len(phone) < 6:
            return phone
        return phone[:3] + '***' + phone[-4:]


class EmailOTPSender:
    """
    Send OTP via Email using Brevo (Sendinblue) SMTP.
    """
    
    @staticmethod
    def send(email: str, otp: str, username: str = '') -> Tuple[bool, str]:
        """
        Send OTP to email address via Brevo SMTP.
        
        Returns: (success, message)
        """
        import smtplib
        import os
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        # Get credentials from environment
        mail_host = os.getenv('MAIL_HOST', 'smtp-relay.brevo.com')
        mail_port = int(os.getenv('MAIL_PORT', '587'))
        mail_username = os.getenv('MAIL_USERNAME', '')
        mail_password = os.getenv('MAIL_PASSWORD', '')
        
        if not mail_username or not mail_password:
            logger.error("Brevo SMTP credentials not configured")
            # Fallback to debug mode
            print(f"\n{'='*50}")
            print(f"📧 EMAIL OTP (No SMTP configured)")
            print(f"To: {email}")
            print(f"OTP: {otp}")
            print(f"{'='*50}\n")
            return True, f"OTP sent to {OTPService.mask_email(email)}"
        
        try:
            # Create email message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = f'🔐 Mã xác thực LUNA: {otp}'
            msg['From'] = 'LUNA <khangnhanopi@gmail.com>'
            msg['To'] = email
            
            # HTML email template
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; padding: 20px; }}
                    .container {{ max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }}
                    .logo {{ text-align: center; margin-bottom: 30px; }}
                    .logo-icon {{ font-size: 48px; }}
                    .title {{ color: #FF6B9D; font-size: 24px; text-align: center; margin-bottom: 10px; }}
                    .subtitle {{ color: #666; text-align: center; margin-bottom: 30px; }}
                    .otp-box {{ background: linear-gradient(135deg, #FF6B9D 0%, #C86DD7 100%); border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0; }}
                    .otp-code {{ font-size: 36px; font-weight: bold; color: white; letter-spacing: 8px; }}
                    .footer {{ color: #999; font-size: 12px; text-align: center; margin-top: 30px; }}
                    .warning {{ color: #FF6B9D; font-size: 13px; text-align: center; margin-top: 20px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="logo">
                        <div class="logo-icon">🌸</div>
                    </div>
                    <h1 class="title">LUNA</h1>
                    <p class="subtitle">Ứng dụng chăm sóc sức khỏe phụ nữ</p>
                    
                    <p style="color: #333; text-align: center;">
                        Xin chào{' ' + username if username else ''},<br>
                        Mã xác thực tài khoản của bạn là:
                    </p>
                    
                    <div class="otp-box">
                        <div class="otp-code">{otp}</div>
                    </div>
                    
                    <p class="warning">
                        ⏰ Mã này sẽ hết hạn sau 5 phút.<br>
                        🔒 Không chia sẻ mã này với bất kỳ ai.
                    </p>
                    
                    <div class="footer">
                        <p>Email này được gửi tự động từ LUNA App.</p>
                        <p>Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.</p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            # Plain text fallback
            text_content = f"""
            LUNA - Xác thực tài khoản
            
            Mã OTP của bạn: {otp}
            
            Mã này sẽ hết hạn sau 5 phút.
            Không chia sẻ mã này với bất kỳ ai.
            """
            
            msg.attach(MIMEText(text_content, 'plain', 'utf-8'))
            msg.attach(MIMEText(html_content, 'html', 'utf-8'))
            
            # Send email via SMTP
            with smtplib.SMTP(mail_host, mail_port) as server:
                server.starttls()
                server.login(mail_username, mail_password)
                server.sendmail(mail_username, email, msg.as_string())
            
            logger.info(f"[EMAIL OTP] Successfully sent OTP to {email}")
            return True, f"OTP sent to {OTPService.mask_email(email)}"
            
        except smtplib.SMTPAuthenticationError as e:
            logger.error(f"[EMAIL OTP] SMTP Auth failed: {e}")
            return False, "Email service authentication failed"
        except smtplib.SMTPException as e:
            logger.error(f"[EMAIL OTP] SMTP error: {e}")
            return False, "Failed to send email"
        except Exception as e:
            logger.error(f"[EMAIL OTP] Unexpected error: {e}")
            return False, f"Email sending failed: {str(e)}"


class SMSOTPSender:
    """
    Send OTP via SMS.
    
    TODO: Integrate with SMS provider when credentials are provided.
    """
    
    @staticmethod
    def send(phone: str, otp: str) -> Tuple[bool, str]:
        """
        Send OTP to phone number.
        
        Returns: (success, message)
        """
        # TODO: Replace with actual SMS API call
        logger.info(f"[SMS OTP] Would send OTP {otp} to {phone}")
        
        # For development, just log it
        print(f"\n{'='*50}")
        print(f"📱 SMS OTP (Development Mode)")
        print(f"To: {phone}")
        print(f"OTP: {otp}")
        print(f"{'='*50}\n")
        
        return True, f"OTP sent to {OTPService.mask_phone(phone)}"
