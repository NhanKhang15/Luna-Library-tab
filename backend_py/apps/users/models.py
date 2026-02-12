"""
User model - Map to new dbo.Users schema.

Schema:
- UserID (INT, PK, IDENTITY)
- Username (VARCHAR 50, UNIQUE, NOT NULL)
- Email (VARCHAR 100, UNIQUE, NULL)
- PhoneNumber (NVARCHAR 20, NULL)
- PasswordHashed (VARBINARY 255, NULL)
- SocialProvider (VARCHAR 20, NULL) - 'google', 'facebook', 'Apple'
- SocialUID (VARCHAR 255, NULL)
- AuthPrimary (VARCHAR 20, NOT NULL, DEFAULT 'local') - 'local', 'google', 'facebook', 'Apple'
- Status (VARCHAR 20, NOT NULL, DEFAULT 'active') - 'active', 'disabled', 'banned'
- CreatedAt (DATETIME2, NOT NULL)
- profile_completed (BIT, NOT NULL, DEFAULT 0)
- AccountVerified (BIT, NOT NULL, DEFAULT 0)
"""

from django.db import models


class User(models.Model):
    """User model mapped to dbo.Users table."""
    
    # Auth primary choices
    AUTH_LOCAL = 'local'
    AUTH_GOOGLE = 'google'
    AUTH_FACEBOOK = 'facebook'
    AUTH_APPLE = 'Apple'
    AUTH_PRIMARY_CHOICES = [
        (AUTH_LOCAL, 'Local'),
        (AUTH_GOOGLE, 'Google'),
        (AUTH_FACEBOOK, 'Facebook'),
        (AUTH_APPLE, 'Apple'),
    ]
    
    # Status choices
    STATUS_ACTIVE = 'active'
    STATUS_DISABLED = 'disabled'
    STATUS_BANNED = 'banned'
    STATUS_CHOICES = [
        (STATUS_ACTIVE, 'Active'),
        (STATUS_DISABLED, 'Disabled'),
        (STATUS_BANNED, 'Banned'),
    ]
    
    # Social provider choices
    SOCIAL_GOOGLE = 'google'
    SOCIAL_FACEBOOK = 'facebook'
    SOCIAL_APPLE = 'Apple'
    SOCIAL_PROVIDER_CHOICES = [
        (SOCIAL_GOOGLE, 'Google'),
        (SOCIAL_FACEBOOK, 'Facebook'),
        (SOCIAL_APPLE, 'Apple'),
    ]
    
    # Primary key
    user_id = models.AutoField(primary_key=True, db_column='UserID')
    
    # Basic info
    username = models.CharField(
        max_length=50, 
        unique=True, 
        db_column='Username'
    )
    email = models.CharField(
        max_length=100, 
        unique=True, 
        null=True, 
        blank=True, 
        db_column='Email'
    )
    phone_number = models.CharField(
        max_length=20, 
        null=True, 
        blank=True, 
        db_column='PhoneNumber'
    )
    
    # Password - stored as VARBINARY in SQL Server
    # We store BCrypt hash as bytes
    password_hashed = models.BinaryField(
        null=True, 
        blank=True, 
        db_column='PasswordHashed'
    )
    
    # Social login fields
    social_provider = models.CharField(
        max_length=20,
        null=True,
        blank=True,
        choices=SOCIAL_PROVIDER_CHOICES,
        db_column='SocialProvider'
    )
    social_uid = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        db_column='SocialUID'
    )
    
    # Auth type and status
    auth_primary = models.CharField(
        max_length=20,
        choices=AUTH_PRIMARY_CHOICES,
        default=AUTH_LOCAL,
        db_column='AuthPrimary'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_ACTIVE,
        db_column='Status'
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True, 
        db_column='CreatedAt'
    )
    
    # Profile flags
    profile_completed = models.BooleanField(
        default=False, 
        db_column='profile_completed'
    )
    account_verified = models.BooleanField(
        default=False, 
        db_column='AccountVerified'
    )

    class Meta:
        db_table = 'Users'
        managed = False  # Don't let Django manage this table
        
    def __str__(self):
        return f"{self.username} ({self.email or 'no email'})"
    
    @property
    def is_active(self) -> bool:
        """Check if account is active."""
        return self.status == self.STATUS_ACTIVE
    
    @property
    def is_local_auth(self) -> bool:
        """Check if using local authentication."""
        return self.auth_primary == self.AUTH_LOCAL
    
    @property
    def is_social_auth(self) -> bool:
        """Check if using social authentication."""
        return self.auth_primary in [self.AUTH_GOOGLE, self.AUTH_FACEBOOK, self.AUTH_APPLE]
    
    @property
    def can_login(self) -> bool:
        """Check if user can login (active + verified for local auth)."""
        if self.status != self.STATUS_ACTIVE:
            return False
        # Social auth doesn't need verification
        if self.is_social_auth:
            return True
        # Local auth requires verification
        return self.account_verified
