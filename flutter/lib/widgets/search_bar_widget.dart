import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Search bar with outer card that transitions to primaryGradient on focus
class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onHelpTap;

  const SearchBarWidget({super.key, this.onChanged, this.onHelpTap});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  // Colors
  static const Color _outerDefault = Color(0xFFF3EFF6); // milky off-white
  static const Color _innerBg = Color(0xFFFFFFFF); // pure white
  static const Color _hintColor = Color(0xFFBDBDBD);
  static const Color _iconColor = Color(0xFFBDBDBD);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          // Gradient on focus, milky off-white when idle
          gradient: _isFocused ? AppColors.primaryGradient : null,
          color: _isFocused ? null : _outerDefault,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _innerBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 22, color: _iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {});
                    widget.onChanged?.call(value);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm nội dung...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _hintColor,
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
              const SizedBox(width: 12),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, size: 20, color: _iconColor),
                  ),
                )
              else
                GestureDetector(
                  onTap: widget.onHelpTap,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _iconColor, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
