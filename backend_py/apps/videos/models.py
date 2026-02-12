"""
Video models - Map to existing Videos, VideoStats, VideoLikes, VideoCategories, VideoTags tables.
"""

from django.db import models
from apps.experts.models import Expert
from apps.tags.models import Tag, ContentCategory


class Video(models.Model):
    """Video model mapping to dbo.Videos table."""
    video_id = models.AutoField(primary_key=True, db_column='video_id')
    expert = models.ForeignKey(
        Expert, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        db_column='expert_id',
        related_name='videos'
    )
    title = models.CharField(max_length=255, db_column='title')
    description = models.TextField(null=True, blank=True, db_column='description')
    thumbnail_url = models.CharField(max_length=500, null=True, blank=True, db_column='thumbnail_url')
    video_url = models.CharField(max_length=500, db_column='video_url')
    duration_seconds = models.IntegerField(default=0, db_column='duration_seconds')
    is_short = models.BooleanField(default=False, db_column='is_short')
    is_premium = models.BooleanField(default=False, db_column='is_premium')
    status = models.CharField(max_length=20, default='draft', db_column='status')
    published_at = models.DateTimeField(null=True, blank=True, db_column='published_at')
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')
    updated_at = models.DateTimeField(auto_now=True, db_column='updated_at')
    
    # ManyToMany relations for easier access
    categories = models.ManyToManyField(
        ContentCategory,
        through='VideoCategory',
        related_name='videos'
    )
    tags = models.ManyToManyField(
        Tag,
        through='VideoTag',
        related_name='videos'
    )

    class Meta:
        db_table = 'Videos'
        managed = False

    def __str__(self):
        return self.title


class VideoStats(models.Model):
    """Video statistics, mapping to dbo.VideoStats table."""
    video = models.OneToOneField(
        Video, 
        on_delete=models.CASCADE, 
        primary_key=True,
        db_column='video_id',
        related_name='stats'
    )
    view_count = models.IntegerField(default=0, db_column='view_count')
    like_count = models.IntegerField(default=0, db_column='like_count')
    updated_at = models.DateTimeField(auto_now=True, db_column='updated_at')

    class Meta:
        db_table = 'VideoStats'
        managed = False


class VideoLike(models.Model):
    """Video like, mapping to dbo.VideoLikes table.
    
    Note: Table uses composite PK (user_id, video_id). Django doesn't support
    composite PKs, so we use user_id as PK with video as a unique_together constraint.
    """
    user_id = models.IntegerField(primary_key=True, db_column='user_id')
    video = models.ForeignKey(
        Video, 
        on_delete=models.CASCADE,
        db_column='video_id',
        related_name='likes'
    )
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')

    class Meta:
        db_table = 'VideoLikes'
        managed = False
        unique_together = [['user_id', 'video']]


class VideoCategory(models.Model):
    """Video-Category junction table - uses video_id as pk for Django compatibility."""
    video = models.ForeignKey(
        Video,
        on_delete=models.CASCADE,
        db_column='video_id',
        primary_key=True,
        related_name='video_categories'
    )
    category = models.ForeignKey(
        ContentCategory,
        on_delete=models.CASCADE,
        db_column='category_id'
    )

    class Meta:
        db_table = 'VideoCategories'
        managed = False


class VideoTag(models.Model):
    """Video-Tag junction table - uses video_id as pk for Django compatibility."""
    video = models.ForeignKey(
        Video,
        on_delete=models.CASCADE,
        db_column='video_id',
        primary_key=True,
        related_name='video_tags'
    )
    tag = models.ForeignKey(
        Tag,
        on_delete=models.CASCADE,
        db_column='tag_id',
        related_name='video_tags'
    )

    class Meta:
        db_table = 'VideoTags'
        managed = False

