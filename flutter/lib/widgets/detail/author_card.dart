import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';

class AuthorCard extends StatelessWidget {
  final String name;
  final String role;
  final String? avatarUrl;
  final double rating;
  final int ratingCount;
  final VoidCallback? onFollowTap;
  final VoidCallback? onScheduleTap;

  const AuthorCard({
    super.key,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.rating,
    required this.ratingCount,
    this.onFollowTap,
    this.onScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 219, 231),
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            backgroundColor: Colors.grey[300],
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppStyles.spacingM),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$rating ($ratingCount+ đánh giá)',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Follow Button
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: onFollowTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Follow', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),

              // Schedule Button
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onScheduleTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors
                        .primary, // Using primary for filled look per design, or use AppColors.primaryGradient if supported by buttons directly (needs Container)
                    // For exact gradient match as per other buttons, might need a Container.
                    // But Figma image shows a solid purple button for "Đặt lịch".
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                    ),
                  ),
                  child: const Text('Đặt lịch', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
