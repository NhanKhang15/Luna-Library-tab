import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';

/// Stats card matching the design (Kinh nghiệm, Buổi tư vấn)
class StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingL,
        vertical: AppStyles.spacingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            value,
            style: AppStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
