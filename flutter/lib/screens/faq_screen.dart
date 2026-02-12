import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_styles.dart';
import '../widgets/bottom_nav_bar.dart';

// ─────────────────────────────────────────────
// FAQ Screen - Pixel-perfect Figma implementation
// ─────────────────────────────────────────────

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _selectedCategory = 'Tâm lý';
  String _searchQuery = '';

  static const Map<String, List<FAQItemData>> _faqData = {
    'Tâm lý': [
      FAQItemData(
        question: 'Làm thế nào để vượt qua cảm giác lo âu thường xuyên?',
        answer:
            'Lo âu thường xuyên có thể được kiểm soát thông qua các phương pháp như '
            'thiền định, hít thở sâu, tập thể dục đều đặn, và duy trì lối sống lành mạnh. '
            'Nếu tình trạng kéo dài, hãy tìm đến chuyên gia tâm lý để được hỗ trợ.',
      ),
      FAQItemData(
        question: 'Làm sao để xây dựng mối quan hệ gia đình hạnh phúc?',
        answer:
            'Xây dựng mối quan hệ gia đình hạnh phúc đòi hỏi sự lắng nghe, '
            'thấu hiểu, và tôn trọng lẫn nhau. Dành thời gian chất lượng cho gia đình, '
            'chia sẻ cảm xúc và cùng nhau giải quyết mâu thuẫn một cách bình tĩnh.',
      ),
      FAQItemData(
        question: 'Khi nào thì nên tìm đến tâm lý trị liệu?',
        answer:
            'Bạn nên tìm đến tâm lý trị liệu khi cảm thấy khó khăn trong việc '
            'quản lý cảm xúc, mất ngủ kéo dài, lo âu hoặc trầm cảm ảnh hưởng đến '
            'cuộc sống hàng ngày, hoặc khi gặp khủng hoảng trong các mối quan hệ.',
      ),
    ],
    'Sinh học': [
      FAQItemData(
        question: 'Chu kỳ kinh nguyệt bình thường kéo dài bao lâu?',
        answer:
            'Chu kỳ kinh nguyệt bình thường kéo dài từ 21 đến 35 ngày, '
            'với thời gian hành kinh từ 3 đến 7 ngày. Nếu chu kỳ bất thường, '
            'hãy tham khảo ý kiến bác sĩ.',
      ),
      FAQItemData(
        question: 'Làm thế nào để giảm đau bụng kinh?',
        answer:
            'Có thể giảm đau bụng kinh bằng cách chườm ấm, tập yoga nhẹ nhàng, '
            'uống trà gừng, và nghỉ ngơi đầy đủ. Nếu cơn đau quá nghiêm trọng, '
            'hãy gặp bác sĩ để được tư vấn.',
      ),
    ],
    'Pháp lý': [
      FAQItemData(
        question: 'Quyền lợi của phụ nữ mang thai tại nơi làm việc?',
        answer:
            'Phụ nữ mang thai được bảo vệ bởi Bộ luật Lao động, bao gồm '
            'chế độ nghỉ thai sản, không bị sa thải trong thời gian mang thai, '
            'và được đảm bảo các điều kiện làm việc an toàn.',
      ),
      FAQItemData(
        question: 'Thủ tục đăng ký khai sinh cho trẻ em?',
        answer:
            'Đăng ký khai sinh trong vòng 60 ngày kể từ ngày sinh tại UBND '
            'cấp xã nơi cư trú. Cần chuẩn bị giấy chứng sinh, CMND/CCCD '
            'của cha mẹ, và giấy đăng ký kết hôn (nếu có).',
      ),
    ],
  };

  List<FAQItemData> get _filteredFAQs {
    final items = _faqData[_selectedCategory] ?? [];
    if (_searchQuery.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.question.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _FAQHeader(onBackTap: () => Navigator.of(context).pop()),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Search bar sits on a clean white surface
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FAQSearchBar(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FAQ section on a light pink surface
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8EAF5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Column(
                        children: [
                          _FAQCategoryTabs(
                            selected: _selectedCategory,
                            onSelected: (category) =>
                                setState(() => _selectedCategory = category),
                          ),
                          const SizedBox(height: 16),
                          ..._filteredFAQs.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _FAQAccordionItem(data: item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNavBar(currentIndex: 1, onTap: (_) {}),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAQ Item Data Model
// ─────────────────────────────────────────────

class FAQItemData {
  final String question;
  final String answer;

  const FAQItemData({required this.question, required this.answer});
}

// ─────────────────────────────────────────────
// 1) GRADIENT HEADER
// ─────────────────────────────────────────────

class _FAQHeader extends StatelessWidget {
  final VoidCallback? onBackTap;

  const _FAQHeader({this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE880A8), Color(0xFFB565C8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBackTap,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Câu hỏi thường gặp',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Giải đáp từ chuyên gia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xF2FFFFFF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2) SEARCH BAR
// ─────────────────────────────────────────────

class _FAQSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;

  const _FAQSearchBar({this.onChanged});

  @override
  State<_FAQSearchBar> createState() => _FAQSearchBarState();
}

class _FAQSearchBarState extends State<_FAQSearchBar> {
  final TextEditingController _controller = TextEditingController();

  static const Color _bgColor = Color(0xFFF5F5F5);
  static const Color _hintColor = Color(0xFFBDBDBD);
  static const Color _iconColor = Color(0xFFBDBDBD);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        border: Border.all(color: const Color(0xFFECECEC), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(value);
              },
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm câu hỏi...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged?.call('');
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 3) CATEGORY TABS
// ─────────────────────────────────────────────

class _FAQCategoryTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FAQCategoryTabs({required this.selected, required this.onSelected});

  static const List<String> _tabs = ['Tâm lý', 'Sinh học', 'Pháp lý'];

  // Figma colors
  static const Color _selectedBg = Color(0xFF9B59B6);
  static const Color _containerBg = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _containerBg,
          borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        ),
        child: Row(
          children: _tabs.map((tab) {
            final isSelected = tab == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(tab),
                child: AnimatedContainer(
                  duration: AppStyles.animationNormal,
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: AppStyles.animationNormal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    child: Text(tab),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4) FAQ ACCORDION ITEM
// ─────────────────────────────────────────────

class _FAQAccordionItem extends StatefulWidget {
  final FAQItemData data;

  const _FAQAccordionItem({required this.data});

  @override
  State<_FAQAccordionItem> createState() => _FAQAccordionItemState();
}

class _FAQAccordionItemState extends State<_FAQAccordionItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: AppStyles.animationNormal,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      child: Column(
        children: [
          // Question row
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.data.question,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Answer section as a tinted card inside the pink area
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F0F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF0E8F0),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Text(
                  widget.data.answer,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                    height: 1.65,
                  ),
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppStyles.animationNormal,
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
