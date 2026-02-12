"""
Seed script for FAQ data.
Run: python manage.py shell < apps/faq/seed_faqs.py
"""

import django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.faq.models import FAQ, FAQTag
from apps.tags.models import Tag
from apps.experts.models import Expert
from apps.posts.models import Post

# Get or create tags
def get_or_create_tag(name, slug):
    tag, _ = Tag.objects.get_or_create(slug=slug, defaults={'name': name})
    return tag

tags = {
    'lo-au': get_or_create_tag('lo âu', 'lo-au'),
    'tho-sau': get_or_create_tag('thở sâu', 'tho-sau'),
    'thien-dinh': get_or_create_tag('thiền định', 'thien-dinh'),
    'tap-the-duc': get_or_create_tag('tập thể dục', 'tap-the-duc'),
    'gia-dinh': get_or_create_tag('gia đình', 'gia-dinh'),
    'tam-ly-tri-lieu': get_or_create_tag('tâm lý trị liệu', 'tam-ly-tri-lieu'),
    'kinh-nguyet': get_or_create_tag('kinh nguyệt', 'kinh-nguyet'),
    'suc-khoe': get_or_create_tag('sức khỏe', 'suc-khoe'),
    'dau-bung-kinh': get_or_create_tag('đau bụng kinh', 'dau-bung-kinh'),
    'quyen-loi': get_or_create_tag('quyền lợi', 'quyen-loi'),
    'lao-dong': get_or_create_tag('lao động', 'lao-dong'),
    'khai-sinh': get_or_create_tag('khai sinh', 'khai-sinh'),
}

# Get first expert or None
expert = Expert.objects.first()

# Get first post or None  
source_post = Post.objects.first()

# ── Tâm lý FAQs ──
faq1 = FAQ.objects.create(
    category='tam-ly',
    question='Làm thế nào để vượt qua cảm giác lo âu thường xuyên?',
    answer='Lo âu là một phản ứng tự nhiên của cơ thể trước các tình huống căng thẳng. '
           'Để vượt qua lo âu, bạn có thể áp dụng một số kỹ thuật như: thở sâu, thiền định, '
           'tập thể dục đều đặn, và chia sẻ cảm xúc với người thân. Quan trọng là nhận diện '
           'dấu hiệu lo âu sớm và tìm kiếm sự hỗ trợ chuyên nghiệp khi cần thiết.',
    expert=expert,
    source_post=source_post,
)
for slug in ['lo-au', 'tho-sau', 'thien-dinh', 'tap-the-duc']:
    FAQTag.objects.get_or_create(faq=faq1, tag=tags[slug])

faq2 = FAQ.objects.create(
    category='tam-ly',
    question='Làm sao để xây dựng mối quan hệ gia đình hạnh phúc?',
    answer='Xây dựng mối quan hệ gia đình hạnh phúc đòi hỏi sự lắng nghe, '
           'thấu hiểu, và tôn trọng lẫn nhau. Dành thời gian chất lượng cho gia đình, '
           'chia sẻ cảm xúc và cùng nhau giải quyết mâu thuẫn một cách bình tĩnh.',
    expert=expert,
    source_post=source_post,
)
for slug in ['gia-dinh', 'tam-ly-tri-lieu']:
    FAQTag.objects.get_or_create(faq=faq2, tag=tags[slug])

faq3 = FAQ.objects.create(
    category='tam-ly',
    question='Khi nào thì nên tìm đến tâm lý trị liệu?',
    answer='Bạn nên tìm đến tâm lý trị liệu khi cảm thấy khó khăn trong việc '
           'quản lý cảm xúc, mất ngủ kéo dài, lo âu hoặc trầm cảm ảnh hưởng đến '
           'cuộc sống hàng ngày, hoặc khi gặp khủng hoảng trong các mối quan hệ.',
    expert=expert,
    source_post=None,
)
for slug in ['tam-ly-tri-lieu', 'lo-au']:
    FAQTag.objects.get_or_create(faq=faq3, tag=tags[slug])

# ── Sinh học FAQs ──
faq4 = FAQ.objects.create(
    category='sinh-hoc',
    question='Chu kỳ kinh nguyệt bình thường kéo dài bao lâu?',
    answer='Chu kỳ kinh nguyệt bình thường kéo dài từ 21 đến 35 ngày, '
           'với thời gian hành kinh từ 3 đến 7 ngày. Nếu chu kỳ bất thường, '
           'hãy tham khảo ý kiến bác sĩ.',
    expert=expert,
    source_post=None,
)
for slug in ['kinh-nguyet', 'suc-khoe']:
    FAQTag.objects.get_or_create(faq=faq4, tag=tags[slug])

faq5 = FAQ.objects.create(
    category='sinh-hoc',
    question='Làm thế nào để giảm đau bụng kinh?',
    answer='Có thể giảm đau bụng kinh bằng cách chườm ấm, tập yoga nhẹ nhàng, '
           'uống trà gừng, và nghỉ ngơi đầy đủ. Nếu cơn đau quá nghiêm trọng, '
           'hãy gặp bác sĩ để được tư vấn.',
    expert=expert,
    source_post=None,
)
for slug in ['dau-bung-kinh', 'suc-khoe']:
    FAQTag.objects.get_or_create(faq=faq5, tag=tags[slug])

# ── Pháp lý FAQs ──
faq6 = FAQ.objects.create(
    category='phap-ly',
    question='Quyền lợi của phụ nữ mang thai tại nơi làm việc?',
    answer='Phụ nữ mang thai được bảo vệ bởi Bộ luật Lao động, bao gồm '
           'chế độ nghỉ thai sản, không bị sa thải trong thời gian mang thai, '
           'và được đảm bảo các điều kiện làm việc an toàn.',
    expert=expert,
    source_post=None,
)
for slug in ['quyen-loi', 'lao-dong']:
    FAQTag.objects.get_or_create(faq=faq6, tag=tags[slug])

faq7 = FAQ.objects.create(
    category='phap-ly',
    question='Thủ tục đăng ký khai sinh cho trẻ em?',
    answer='Đăng ký khai sinh trong vòng 60 ngày kể từ ngày sinh tại UBND '
           'cấp xã nơi cư trú. Cần chuẩn bị giấy chứng sinh, CMND/CCCD '
           'của cha mẹ, và giấy đăng ký kết hôn (nếu có).',
    expert=expert,
    source_post=None,
)
for slug in ['khai-sinh', 'quyen-loi']:
    FAQTag.objects.get_or_create(faq=faq7, tag=tags[slug])

print(f'Seeded {FAQ.objects.count()} FAQs with tags.')
