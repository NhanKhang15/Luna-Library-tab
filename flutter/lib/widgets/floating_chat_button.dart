import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_styles.dart';

/// Floating chat button widget
class FloatingChatButton extends StatefulWidget {
  final VoidCallback? onTap;

  const FloatingChatButton({super.key, this.onTap});

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppStyles.spacingL,
      bottom: AppStyles.spacingXXL * 7,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: AnimatedContainer(
            duration: AppStyles.animationFast,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: _isPressed
                  ? AppStyles.shadowLight
                  : AppStyles.shadowElevated,
            ),
            transform: _isPressed
                ? (Matrix4.identity()..scale(0.95))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
