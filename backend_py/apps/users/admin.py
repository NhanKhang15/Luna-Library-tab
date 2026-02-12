"""Users admin configuration - Updated for new schema."""

from django.contrib import admin
from .models import User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['user_id', 'username', 'email', 'auth_primary', 'status', 'account_verified', 'created_at']
    list_filter = ['auth_primary', 'status', 'account_verified']
    search_fields = ['username', 'email', 'phone_number']
    readonly_fields = ['user_id', 'created_at', 'password_hashed']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('username', 'email', 'phone_number')
        }),
        ('Authentication', {
            'fields': ('auth_primary', 'social_provider', 'social_uid', 'password_hashed')
        }),
        ('Status', {
            'fields': ('status', 'account_verified', 'profile_completed')
        }),
        ('Timestamps', {
            'fields': ('created_at',)
        }),
    )
