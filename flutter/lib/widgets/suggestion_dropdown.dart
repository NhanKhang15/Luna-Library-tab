import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Suggestion item data
class SuggestionItem {
  final String id;
  final String label;
  final String? prefix;

  const SuggestionItem({required this.id, required this.label, this.prefix});
}

/// Compact suggestion dropdown with overlay behavior
class SuggestionDropdown extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<String>? onSelectionChanged;

  const SuggestionDropdown({
    super.key,
    this.selectedId,
    this.onSelectionChanged,
  });

  @override
  State<SuggestionDropdown> createState() => _SuggestionDropdownState();
}

class _SuggestionDropdownState extends State<SuggestionDropdown> {
  final GlobalKey _dropdownKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isExpanded = false;
  late String _selectedId;

  static const List<SuggestionItem> _suggestions = [
    SuggestionItem(id: 'all', label: 'Tất cả gợi ý', prefix: '∞'),
    SuggestionItem(
      id: 'mental',
      label: 'Cải thiện sức khỏe tinh thần',
      prefix: 'A',
    ),
    SuggestionItem(
      id: 'relationship',
      label: 'Xây dựng mối quan hệ',
      prefix: 'B',
    ),
    SuggestionItem(id: 'personal', label: 'Phát triển bản thân', prefix: 'C'),
    SuggestionItem(id: 'stress', label: 'Quản lý stress', prefix: 'D'),
    SuggestionItem(id: 'legal', label: 'Hiểu biết pháp lý', prefix: 'E'),
    SuggestionItem(id: 'reproductive', label: 'Sức khỏe sinh sản', prefix: 'F'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId ?? 'all';
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _showOverlay() {
    final RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: _buildDropdownContent(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(String id) {
    setState(() {
      _selectedId = id;
      _isExpanded = false;
    });
    _removeOverlay();
    widget.onSelectionChanged?.call(id);
  }

  Widget _buildDropdownContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _suggestions.map((item) {
          final isSelected = item.id == _selectedId;
          return InkWell(
            onTap: () => _selectItem(item.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (item.prefix != null) ...[
                    SizedBox(
                      width: 18,
                      child: Text(
                        item.prefix!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Figma colors - slightly different from search bar for separation
    const sparkleColor = Color(0xFFCB62A2);
    const textColor = Color(0xFF666666);
    const arrowColor = Color(0xFFBDBDBD);
    const borderColor = Color(0xFFEEEEEE);
    // Dropdown bg slightly less bright than search bar (creates separation)
    const dropdownBgColor = Color(0xFFFCFCFC);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          key: _dropdownKey,
          onTap: _toggleExpanded,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: dropdownBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.5),
              // Subtle shadow - less prominent than search bar
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: sparkleColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gợi ý dựa trên sở thích của bạn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: arrowColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
