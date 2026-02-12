"""
Expert models - Maps to existing Experts and ExpertReviews tables.
"""

from django.db import models


class Expert(models.Model):
    """Expert model mapping to dbo.Experts table."""

    expert_id = models.AutoField(primary_key=True, db_column='expert_id')
    full_name = models.CharField(max_length=100, db_column='full_name')
    specialization = models.CharField(
        max_length=100, null=True, blank=True, db_column='specialization'
    )
    title = models.CharField(max_length=100, null=True, blank=True, db_column='title')
    bio = models.TextField(null=True, blank=True, db_column='bio')
    experience_years = models.IntegerField(default=0, db_column='experience_years')
    price_per_session = models.DecimalField(
        max_digits=18, decimal_places=2, default=0, db_column='price_per_session'
    )
    currency = models.CharField(max_length=10, default='VND', db_column='currency')
    rating = models.DecimalField(
        max_digits=3, decimal_places=1, default=0, db_column='rating'
    )
    rating_count = models.IntegerField(default=0, db_column='rating_count')
    consultation_count = models.IntegerField(default=0, db_column='consultation_count')
    is_verified = models.BooleanField(default=False, db_column='is_verified')
    avatar_url = models.CharField(
        max_length=500, null=True, blank=True, db_column='avatar_url'
    )
    contact_info = models.CharField(
        max_length=255, null=True, blank=True, db_column='contact_info'
    )
    user_id = models.IntegerField(null=True, blank=True, db_column='user_id')
    created_at = models.DateTimeField(null=True, blank=True, db_column='created_at')

    class Meta:
        db_table = 'Experts'
        managed = False

    def __str__(self):
        return self.full_name


class ExpertReview(models.Model):
    """ExpertReview model mapping to dbo.ExpertReviews table."""

    review_id = models.BigAutoField(primary_key=True, db_column='review_id')
    expert = models.ForeignKey(
        Expert,
        on_delete=models.CASCADE,
        db_column='expert_id',
        related_name='reviews',
    )
    user_id = models.IntegerField(db_column='user_id')
    rating = models.IntegerField(db_column='rating')
    comment = models.TextField(null=True, blank=True, db_column='comment')
    created_at = models.DateTimeField(null=True, blank=True, db_column='created_at')
    updated_at = models.DateTimeField(null=True, blank=True, db_column='updated_at')

    class Meta:
        db_table = 'ExpertReviews'
        managed = False

    def __str__(self):
        return f"Review #{self.review_id} for Expert #{self.expert_id}"
