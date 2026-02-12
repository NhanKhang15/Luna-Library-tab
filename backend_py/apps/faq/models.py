"""
FAQ models - FAQs and FAQTags tables.
"""

from django.db import models
from apps.experts.models import Expert
from apps.posts.models import Post
from apps.tags.models import Tag


class FAQ(models.Model):
    """FAQ model mapping to dbo.FAQs table."""
    faq_id = models.AutoField(primary_key=True, db_column='faq_id')
    category = models.CharField(max_length=20, db_column='category')
    question = models.CharField(max_length=500, db_column='question')
    answer = models.TextField(db_column='answer')
    expert = models.ForeignKey(
        Expert,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='expert_id',
        related_name='faqs'
    )
    source_post = models.ForeignKey(
        Post,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='source_post_id',
        related_name='faqs'
    )
    created_at = models.DateTimeField(auto_now_add=True, db_column='created_at')

    tags = models.ManyToManyField(
        Tag,
        through='FAQTag',
        related_name='faqs'
    )

    class Meta:
        db_table = 'FAQs'

    def __str__(self):
        return self.question[:80]


class FAQTag(models.Model):
    """FAQ-Tag junction table."""
    id = models.AutoField(primary_key=True)
    faq = models.ForeignKey(
        FAQ,
        on_delete=models.CASCADE,
        db_column='faq_id',
        related_name='faq_tags'
    )
    tag = models.ForeignKey(
        Tag,
        on_delete=models.CASCADE,
        db_column='tag_id',
        related_name='faq_tags'
    )

    class Meta:
        db_table = 'FAQTags'
        unique_together = [['faq', 'tag']]
