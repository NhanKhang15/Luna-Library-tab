"""OTP admin configuration."""

from django.contrib import admin
from .models import OTPRequest


@admin.register(OTPRequest)
class OTPRequestAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'method', 'target', 'verified', 'attempts', 'created_at', 'expires_at']
    list_filter = ['method', 'verified', 'created_at']
    search_fields = ['user_id', 'target']
    readonly_fields = ['otp_hash', 'created_at']
    ordering = ['-created_at']
