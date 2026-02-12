import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onActionPressed;
  final VoidCallback? onActionTap;  // Alias for onActionPressed
  final IconData? actionIcon;
  final Color? actionIconColor;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBackPressed,
    this.onActionPressed,
    this.onActionTap,
    this.actionIcon,
    this.actionIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onActionTap ?? onActionPressed;
    final effectiveIconColor = actionIconColor ?? Colors.white;
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppStyles.spacingM,
        bottom: AppStyles.spacingM,
        left: AppStyles.spacingM,
        right: AppStyles.spacingM,
      ),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppStyles.radiusPill),
            child: InkWell(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(AppStyles.radiusPill),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppStyles.spacingM),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Action button (optional) - with animated icon color
          if (actionIcon != null)
            Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppStyles.radiusPill),
              child: InkWell(
                onTap: effectiveOnTap,
                borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      actionIcon,
                      key: ValueKey(actionIcon),
                      color: effectiveIconColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
