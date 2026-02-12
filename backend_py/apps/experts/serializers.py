"""Expert serializers."""

from rest_framework import serializers
from .models import Expert, ExpertReview


class ExpertReviewSerializer(serializers.ModelSerializer):
    """Serializer for expert reviews."""

    reviewId = serializers.IntegerField(source='review_id', read_only=True)
    expertId = serializers.IntegerField(source='expert_id', read_only=True)
    userId = serializers.IntegerField(source='user_id', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = ExpertReview
        fields = ['reviewId', 'expertId', 'userId', 'rating', 'comment', 'createdAt']


class ExpertListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for expert list."""

    id = serializers.IntegerField(source='expert_id', read_only=True)
    name = serializers.CharField(source='full_name')
    isVerified = serializers.BooleanField(source='is_verified')
    avatarUrl = serializers.CharField(source='avatar_url', allow_null=True)
    ratingCount = serializers.IntegerField(source='rating_count')
    experienceYears = serializers.IntegerField(source='experience_years')
    pricePerSession = serializers.DecimalField(
        source='price_per_session', max_digits=18, decimal_places=2
    )

    class Meta:
        model = Expert
        fields = [
            'id', 'name', 'title', 'avatarUrl', 'rating',
            'ratingCount', 'isVerified', 'experienceYears', 'pricePerSession',
            'currency',
        ]


# Backward-compatible serializer used by posts, videos, faq serializers.
# Returns the OLD field names (expertId, fullName, specialization).
class ExpertSerializer(serializers.ModelSerializer):
    """Minimal expert info embedded in posts/videos/faq responses."""

    expertId = serializers.IntegerField(source='expert_id', read_only=True)
    fullName = serializers.CharField(source='full_name')

    class Meta:
        model = Expert
        fields = ['expertId', 'fullName', 'specialization']


class ExpertDetailSerializer(serializers.ModelSerializer):
    """Full detail serializer for a single expert."""

    id = serializers.IntegerField(source='expert_id', read_only=True)
    name = serializers.CharField(source='full_name')
    isVerified = serializers.BooleanField(source='is_verified')
    avatarUrl = serializers.CharField(source='avatar_url', allow_null=True)
    ratingCount = serializers.IntegerField(source='rating_count')
    yearsExperience = serializers.IntegerField(source='experience_years')
    consultationCount = serializers.IntegerField(source='consultation_count')
    pricePerSession = serializers.DecimalField(
        source='price_per_session', max_digits=18, decimal_places=2
    )
    priceInfo = serializers.SerializerMethodField()
    primaryTag = serializers.SerializerMethodField()
    specialties = serializers.SerializerMethodField()

    class Meta:
        model = Expert
        fields = [
            'id', 'name', 'title', 'avatarUrl', 'isVerified',
            'rating', 'ratingCount', 'yearsExperience', 'consultationCount',
            'bio', 'pricePerSession', 'currency', 'priceInfo',
            'primaryTag', 'specialties',
        ]

    def get_priceInfo(self, obj):
        """Format price as Vietnamese currency string."""
        price = int(obj.price_per_session) if obj.price_per_session else 0
        return f"{price:,}đ/buổi".replace(',', '.')

    def get_primaryTag(self, obj):
        """Return title as the primary tag fallback."""
        return obj.title or ''

    def get_specialties(self, obj):
        """Return specialties from specialization field or empty list."""
        if obj.specialization:
            return [s.strip() for s in obj.specialization.split(',') if s.strip()]
        return []
