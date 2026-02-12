import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';

/// Specialty tags widget for displaying consultant's expertise areas
class SpecialtyTags extends StatelessWidget {
  final List<String> specialties;

  const SpecialtyTags({super.key, required this.specialties});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppStyles.spacingS,
      runSpacing: AppStyles.spacingS,
      children: specialties.map((specialty) => _buildTag(specialty)).toList(),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingM,
        vertical: AppStyles.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
