import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';

class RelatedContentItem {
  final String imageUrl;
  final String title;
  final String type; // 'article' or 'video'

  const RelatedContentItem({
    required this.imageUrl,
    required this.title,
    required this.type,
  });
}

class RelatedContentGrid extends StatelessWidget {
  final List<RelatedContentItem> items;
  final Function(int) onItemTap;

  const RelatedContentGrid({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nội dung liên quan', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            // Only use 1 column on very small screens (< 340px).
            // On normal mobile widths (360-430px) and above, always use 2 columns as per Figma.
            final isVerySmall = constraints.maxWidth < 340;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isVerySmall ? 1 : 2,
                crossAxisSpacing: AppStyles.spacingM,
                mainAxisSpacing: AppStyles.spacingM,
                // Aspect ratio 0.8 works well for 2-column layout (cards are taller than wide).
                // For 1-column fallback, use a wider ratio to avoid overly tall cards.
                childAspectRatio: isVerySmall ? 1.3 : 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildCard(context, items[index], index);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, RelatedContentItem item, int index) {
    final isVideo = item.type == 'video';

    return GestureDetector(
      onTap: () => onItemTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          boxShadow: AppStyles.shadowLight,
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200]),
                  ),
                  if (isVideo)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon badge
                  Row(
                    children: [
                      Icon(
                        isVideo
                            ? Icons.play_circle_outline
                            : Icons.article_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVideo ? 'Video' : 'Bài viết',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    item.title,
                    style: AppStyles.labelLarge.copyWith(height: 1.3),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
