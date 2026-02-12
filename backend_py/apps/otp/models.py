"""
OTP Request model - Store OTP requests for verification.

We create a separate table for OTP since the main Users table is managed externally.
This table CAN be managed by Django migrations.
"""

from django.db import models
from datetime import datetime, timedelta


class OTPRequest(models.Model):
    """OTP request for account verification."""
    
    METHOD_EMAIL = 'email'
    METHOD_SMS = 'sms'
    METHOD_CHOICES = [
        (METHOD_EMAIL, 'Email'),
        (METHOD_SMS, 'SMS'),
    ]
    
    # Link to user (by ID, not FK since Users table is unmanaged)
    user_id = models.IntegerField(db_index=True)
    
    # OTP hash (we don't store plain OTP)
    otp_hash = models.CharField(max_length=128)
    
    # Delivery method
    method = models.CharField(
        max_length=10,
        choices=METHOD_CHOICES,
        default=METHOD_EMAIL
    )
    
    # Target (email or phone)
    target = models.CharField(max_length=100)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    # Status
    verified = models.BooleanField(default=False, db_column='is_verified')
    attempts = models.IntegerField(default=0)
    
    class Meta:
        db_table = 'OTPRequests'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user_id', 'verified']),
        ]
    
    def __str__(self):
        return f"OTP for user {self.user_id} via {self.method}"
    
    @property
    def is_expired(self) -> bool:
        """Check if OTP has expired."""
        from django.utils import timezone
        return timezone.now() > self.expires_at
    
    @property
    def can_attempt(self) -> bool:
        """Check if user can still attempt (max 5 attempts)."""
        return self.attempts < 5 and not self.is_expired
    
    @classmethod
    def get_expiry_time(cls, minutes: int = 5) -> datetime:
        """Get expiry datetime from now."""
        from django.utils import timezone
        return timezone.now() + timedelta(minutes=minutes)
