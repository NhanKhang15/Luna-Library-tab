"""
Tags and Categories models - Map to existing tables.
"""

from django.db import models


class Tag(models.Model):
    """Tag model mapping to dbo.Tags table."""
    tag_id = models.AutoField(primary_key=True, db_column='tag_id')
    name = models.CharField(max_length=80, db_column='name')
    slug = models.CharField(max_length=120, db_column='slug')
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')

    class Meta:
        db_table = 'Tags'
        managed = False

    def __str__(self):
        return self.name


class ContentCategory(models.Model):
    """Category model mapping to dbo.ContentCategories table."""
    category_id = models.AutoField(primary_key=True, db_column='category_id')
    name = models.CharField(max_length=120, db_column='name')
    slug = models.CharField(max_length=160, db_column='slug')
    description = models.TextField(null=True, blank=True, db_column='description')
    is_active = models.BooleanField(default=True, db_column='is_active')
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')

    class Meta:
        db_table = 'ContentCategories'
        managed = False
        verbose_name_plural = 'Content Categories'

    def __str__(self):
        return self.name
