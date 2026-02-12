"""
Post models - Map to existing Posts, PostStats, PostLikes, PostCategories, PostTags tables.
"""

from django.db import models
from apps.experts.models import Expert
from apps.tags.models import Tag, ContentCategory


class Post(models.Model):
    """Post model mapping to dbo.Posts table."""
    post_id = models.AutoField(primary_key=True, db_column='post_id')
    expert = models.ForeignKey(
        Expert, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        db_column='expert_id',
        related_name='posts'
    )
    title = models.CharField(max_length=255, db_column='title')
    summary = models.CharField(max_length=500, null=True, blank=True, db_column='summary')
    content = models.TextField(db_column='content')
    thumbnail_url = models.CharField(max_length=500, null=True, blank=True, db_column='thumbnail_url')
    is_premium = models.BooleanField(default=False, db_column='is_premium')
    status = models.CharField(max_length=20, default='draft', db_column='status')
    published_at = models.DateTimeField(null=True, blank=True, db_column='published_at')
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')
    updated_at = models.DateTimeField(auto_now=True, db_column='updated_at')
    
    # ManyToMany relations for easier access
    categories = models.ManyToManyField(
        ContentCategory,
        through='PostCategory',
        related_name='posts'
    )
    tags = models.ManyToManyField(
        Tag,
        through='PostTag',
        related_name='posts'
    )

    class Meta:
        db_table = 'Posts'
        managed = False

    def __str__(self):
        return self.title


class PostStats(models.Model):
    """Post statistics, mapping to dbo.PostStats table."""
    post = models.OneToOneField(
        Post, 
        on_delete=models.CASCADE, 
        primary_key=True,
        db_column='post_id',
        related_name='stats'
    )
    view_count = models.IntegerField(default=0, db_column='view_count')
    like_count = models.IntegerField(default=0, db_column='like_count')
    updated_at = models.DateTimeField(auto_now=True, db_column='updated_at')

    class Meta:
        db_table = 'PostStats'
        managed = False


class PostLike(models.Model):
    """Post like, mapping to dbo.PostLikes table.
    
    Note: Table uses composite PK (user_id, post_id). Django doesn't support
    composite PKs, so we use user_id as PK with post as a unique_together constraint.
    """
    user_id = models.IntegerField(primary_key=True, db_column='user_id')
    post = models.ForeignKey(
        Post, 
        on_delete=models.CASCADE,
        db_column='post_id',
        related_name='likes'
    )
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')

    class Meta:
        db_table = 'PostLikes'
        managed = False
        unique_together = [['user_id', 'post']]


class PostCategory(models.Model):
    """Post-Category junction table - uses post_id as pk for Django compatibility."""
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        db_column='post_id',
        primary_key=True,
        related_name='post_categories'
    )
    category = models.ForeignKey(
        ContentCategory,
        on_delete=models.CASCADE,
        db_column='category_id'
    )

    class Meta:
        db_table = 'PostCategories'
        managed = False


class PostTag(models.Model):
    """Post-Tag junction table - uses post_id as pk for Django compatibility."""
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        db_column='post_id',
        primary_key=True,
        related_name='post_tags'
    )
    tag = models.ForeignKey(
        Tag,
        on_delete=models.CASCADE,
        db_column='tag_id',
        related_name='post_tags'
    )

    class Meta:
        db_table = 'PostTags'
        managed = False

