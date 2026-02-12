# -*- coding: utf-8 -*-
"""
Seed FAQs management command.
Usage: python manage.py seed_faqs
"""

from django.core.management.base import BaseCommand
from apps.faq.models import FAQ, FAQTag
from apps.tags.models import Tag
from apps.experts.models import Expert
from apps.posts.models import Post


class Command(BaseCommand):
    help = 'Seed FAQ data'

    def handle(self, *args, **options):
        # Clear existing
        FAQ.objects.all().delete()

        def get_or_create_tag(name, slug):
            tag, _ = Tag.objects.get_or_create(slug=slug, defaults={'name': name})
            return tag

        tags = {
            'lo-au': get_or_create_tag('lo \u00e2u', 'lo-au'),
            'tho-sau': get_or_create_tag('th\u1edf s\u00e2u', 'tho-sau'),
            'thien-dinh': get_or_create_tag('thi\u1ec1n \u0111\u1ecbnh', 'thien-dinh'),
            'tap-the-duc': get_or_create_tag('t\u1eadp th\u1ec3 d\u1ee5c', 'tap-the-duc'),
            'gia-dinh': get_or_create_tag('gia \u0111\u00ecnh', 'gia-dinh'),
            'tam-ly-tri-lieu': get_or_create_tag('t\u00e2m l\u00fd tr\u1ecb li\u1ec7u', 'tam-ly-tri-lieu'),
            'kinh-nguyet': get_or_create_tag('kinh nguy\u1ec7t', 'kinh-nguyet'),
            'suc-khoe': get_or_create_tag('s\u1ee9c kh\u1ecfe', 'suc-khoe'),
            'dau-bung-kinh': get_or_create_tag('\u0111au b\u1ee5ng kinh', 'dau-bung-kinh'),
            'quyen-loi': get_or_create_tag('quy\u1ec1n l\u1ee3i', 'quyen-loi'),
            'lao-dong': get_or_create_tag('lao \u0111\u1ed9ng', 'lao-dong'),
            'khai-sinh': get_or_create_tag('khai sinh', 'khai-sinh'),
        }

        expert = Expert.objects.first()
        source_post = Post.objects.first()

        faq_data = [
            {
                'category': 'tam-ly',
                'question': 'L\u00e0m th\u1ebf n\u00e0o \u0111\u1ec3 v\u01b0\u1ee3t qua c\u1ea3m gi\u00e1c lo \u00e2u th\u01b0\u1eddng xuy\u00ean?',
                'answer': 'Lo \u00e2u l\u00e0 m\u1ed9t ph\u1ea3n \u1ee9ng t\u1ef1 nhi\u00ean c\u1ee7a c\u01a1 th\u1ec3 tr\u01b0\u1edbc c\u00e1c t\u00ecnh hu\u1ed1ng c\u0103ng th\u1eb3ng. \u0110\u1ec3 v\u01b0\u1ee3t qua lo \u00e2u, b\u1ea1n c\u00f3 th\u1ec3 \u00e1p d\u1ee5ng m\u1ed9t s\u1ed1 k\u1ef9 thu\u1eadt nh\u01b0: th\u1edf s\u00e2u, thi\u1ec1n \u0111\u1ecbnh, t\u1eadp th\u1ec3 d\u1ee5c \u0111\u1ec1u \u0111\u1eb7n, v\u00e0 chia s\u1ebb c\u1ea3m x\u00fac v\u1edbi ng\u01b0\u1eddi th\u00e2n. Quan tr\u1ecdng l\u00e0 nh\u1eadn di\u1ec7n d\u1ea5u hi\u1ec7u lo \u00e2u s\u1edbm v\u00e0 t\u00ecm ki\u1ebfm s\u1ef1 h\u1ed7 tr\u1ee3 chuy\u00ean nghi\u1ec7p khi c\u1ea7n thi\u1ebft.',
                'tags': ['lo-au', 'tho-sau', 'thien-dinh', 'tap-the-duc'],
                'source_post': source_post,
            },
            {
                'category': 'tam-ly',
                'question': 'L\u00e0m sao \u0111\u1ec3 x\u00e2y d\u1ef1ng m\u1ed1i quan h\u1ec7 gia \u0111\u00ecnh h\u1ea1nh ph\u00fac?',
                'answer': 'X\u00e2y d\u1ef1ng m\u1ed1i quan h\u1ec7 gia \u0111\u00ecnh h\u1ea1nh ph\u00fac \u0111\u00f2i h\u1ecfi s\u1ef1 l\u1eafng nghe, th\u1ea5u hi\u1ec3u, v\u00e0 t\u00f4n tr\u1ecdng l\u1eabn nhau. D\u00e0nh th\u1eddi gian ch\u1ea5t l\u01b0\u1ee3ng cho gia \u0111\u00ecnh, chia s\u1ebb c\u1ea3m x\u00fac v\u00e0 c\u00f9ng nhau gi\u1ea3i quy\u1ebft m\u00e2u thu\u1eabn m\u1ed9t c\u00e1ch b\u00ecnh t\u0129nh.',
                'tags': ['gia-dinh', 'tam-ly-tri-lieu'],
                'source_post': source_post,
            },
            {
                'category': 'tam-ly',
                'question': 'Khi n\u00e0o th\u00ec n\u00ean t\u00ecm \u0111\u1ebfn t\u00e2m l\u00fd tr\u1ecb li\u1ec7u?',
                'answer': 'B\u1ea1n n\u00ean t\u00ecm \u0111\u1ebfn t\u00e2m l\u00fd tr\u1ecb li\u1ec7u khi c\u1ea3m th\u1ea5y kh\u00f3 kh\u0103n trong vi\u1ec7c qu\u1ea3n l\u00fd c\u1ea3m x\u00fac, m\u1ea5t ng\u1ee7 k\u00e9o d\u00e0i, lo \u00e2u ho\u1eb7c tr\u1ea7m c\u1ea3m \u1ea3nh h\u01b0\u1edfng \u0111\u1ebfn cu\u1ed9c s\u1ed1ng h\u00e0ng ng\u00e0y, ho\u1eb7c khi g\u1eb7p kh\u1ee7ng ho\u1ea3ng trong c\u00e1c m\u1ed1i quan h\u1ec7.',
                'tags': ['tam-ly-tri-lieu', 'lo-au'],
                'source_post': None,
            },
            {
                'category': 'sinh-hoc',
                'question': 'Chu k\u1ef3 kinh nguy\u1ec7t b\u00ecnh th\u01b0\u1eddng k\u00e9o d\u00e0i bao l\u00e2u?',
                'answer': 'Chu k\u1ef3 kinh nguy\u1ec7t b\u00ecnh th\u01b0\u1eddng k\u00e9o d\u00e0i t\u1eeb 21 \u0111\u1ebfn 35 ng\u00e0y, v\u1edbi th\u1eddi gian h\u00e0nh kinh t\u1eeb 3 \u0111\u1ebfn 7 ng\u00e0y. N\u1ebfu chu k\u1ef3 b\u1ea5t th\u01b0\u1eddng, h\u00e3y tham kh\u1ea3o \u00fd ki\u1ebfn b\u00e1c s\u0129.',
                'tags': ['kinh-nguyet', 'suc-khoe'],
                'source_post': None,
            },
            {
                'category': 'sinh-hoc',
                'question': 'L\u00e0m th\u1ebf n\u00e0o \u0111\u1ec3 gi\u1ea3m \u0111au b\u1ee5ng kinh?',
                'answer': 'C\u00f3 th\u1ec3 gi\u1ea3m \u0111au b\u1ee5ng kinh b\u1eb1ng c\u00e1ch ch\u01b0\u1eddm \u1ea5m, t\u1eadp yoga nh\u1eb9 nh\u00e0ng, u\u1ed1ng tr\u00e0 g\u1eebng, v\u00e0 ngh\u1ec9 ng\u01a1i \u0111\u1ea7y \u0111\u1ee7. N\u1ebfu c\u01a1n \u0111au qu\u00e1 nghi\u00eam tr\u1ecdng, h\u00e3y g\u1eb7p b\u00e1c s\u0129 \u0111\u1ec3 \u0111\u01b0\u1ee3c t\u01b0 v\u1ea5n.',
                'tags': ['dau-bung-kinh', 'suc-khoe'],
                'source_post': None,
            },
            {
                'category': 'phap-ly',
                'question': 'Quy\u1ec1n l\u1ee3i c\u1ee7a ph\u1ee5 n\u1eef mang thai t\u1ea1i n\u01a1i l\u00e0m vi\u1ec7c?',
                'answer': 'Ph\u1ee5 n\u1eef mang thai \u0111\u01b0\u1ee3c b\u1ea3o v\u1ec7 b\u1edfi B\u1ed9 lu\u1eadt Lao \u0111\u1ed9ng, bao g\u1ed3m ch\u1ebf \u0111\u1ed9 ngh\u1ec9 thai s\u1ea3n, kh\u00f4ng b\u1ecb sa th\u1ea3i trong th\u1eddi gian mang thai, v\u00e0 \u0111\u01b0\u1ee3c \u0111\u1ea3m b\u1ea3o c\u00e1c \u0111i\u1ec1u ki\u1ec7n l\u00e0m vi\u1ec7c an to\u00e0n.',
                'tags': ['quyen-loi', 'lao-dong'],
                'source_post': None,
            },
            {
                'category': 'phap-ly',
                'question': 'Th\u1ee7 t\u1ee5c \u0111\u0103ng k\u00fd khai sinh cho tr\u1ebb em?',
                'answer': '\u0110\u0103ng k\u00fd khai sinh trong v\u00f2ng 60 ng\u00e0y k\u1ec3 t\u1eeb ng\u00e0y sinh t\u1ea1i UBND c\u1ea5p x\u00e3 n\u01a1i c\u01b0 tr\u00fa. C\u1ea7n chu\u1ea9n b\u1ecb gi\u1ea5y ch\u1ee9ng sinh, CMND/CCCD c\u1ee7a cha m\u1eb9, v\u00e0 gi\u1ea5y \u0111\u0103ng k\u00fd k\u1ebft h\u00f4n (n\u1ebfu c\u00f3).',
                'tags': ['khai-sinh', 'quyen-loi'],
                'source_post': None,
            },
        ]

        for item in faq_data:
            faq = FAQ.objects.create(
                category=item['category'],
                question=item['question'],
                answer=item['answer'],
                expert=expert,
                source_post=item['source_post'],
            )
            for slug in item['tags']:
                FAQTag.objects.get_or_create(faq=faq, tag=tags[slug])

        self.stdout.write(self.style.SUCCESS(
            f'Seeded {FAQ.objects.count()} FAQs with tags.'
        ))
