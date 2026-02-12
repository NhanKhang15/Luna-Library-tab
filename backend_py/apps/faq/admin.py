"""FAQ admin registration."""

from django.contrib import admin
from .models import FAQ, FAQTag


class FAQTagInline(admin.TabularInline):
    model = FAQTag
    extra = 1


@admin.register(FAQ)
class FAQAdmin(admin.ModelAdmin):
    list_display = ['faq_id', 'category', 'question', 'expert']
    list_filter = ['category']
    search_fields = ['question', 'answer']
    inlines = [FAQTagInline]
