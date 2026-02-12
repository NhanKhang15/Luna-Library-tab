import 'package:flutter/material.dart';

/// Content type enum
enum ContentType { articles, videos }

/// Content toggle matching Figma design exactly
class ContentToggle extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType>? onChanged;

  const ContentToggle({super.key, required this.selectedType, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // "Bài viết nền tảng" button
          Expanded(
            child: _ToggleButton(
              icon: Icons.article_outlined,
              label: 'Bài viết nền tảng',
              isSelected: selectedType == ContentType.articles,
              onTap: () => onChanged?.call(ContentType.articles),
            ),
          ),
          const SizedBox(width: 12),
          // "Video chuyên gia" button
          Expanded(
            child: _ToggleButton(
              icon: Icons.play_circle_outline,
              label: 'Video chuyên gia',
              isSelected: selectedType == ContentType.videos,
              onTap: () => onChanged?.call(ContentType.videos),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  // Figma colors
  static const Color _inactiveBorder = Color(0xFFE8E8E8);
  static const Color _inactiveText = Color(0xFF666666);

  // Figma gradient (pink to purple)
  static const LinearGradient _activeGradient = LinearGradient(
    colors: [Color(0xFFE75A9D), Color(0xFFC86DD7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44, // Slightly taller like Figma
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          // Use gradient if selected, otherwise white with border
          gradient: isSelected ? _activeGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22), // Pill shape like Figma
          border: isSelected
              ? null
              : Border.all(color: _inactiveBorder, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE75A9D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : _inactiveText,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _inactiveText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
