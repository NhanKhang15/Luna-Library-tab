import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';
import '../../models/related_content.dart';

/// Carousel widget for displaying related content with prev/next navigation
class RelatedContentCarousel extends StatefulWidget {
  final List<RelatedContentItem> items;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoading;
  final Function(RelatedContentItem item) onItemTap;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;

  const RelatedContentCarousel({
    super.key,
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.isLoading = false,
    required this.onItemTap,
    this.onNextPage,
    this.onPreviousPage,
  });

  @override
  State<RelatedContentCarousel> createState() => _RelatedContentCarouselState();
}

class _RelatedContentCarouselState extends State<RelatedContentCarousel> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: AppStyles.animationNormal,
        curve: Curves.easeInOut,
      );
    } else if (widget.currentPage > 1 && widget.onPreviousPage != null) {
      // Fetch previous API page
      widget.onPreviousPage!();
    }
  }

  void _goToNextPage() {
    final totalLocalPages = (widget.items.length / 2).ceil();
    if (_currentPageIndex < totalLocalPages - 1) {
      _pageController.nextPage(
        duration: AppStyles.animationNormal,
        curve: Curves.easeInOut,
      );
    } else if (widget.hasMore && widget.onNextPage != null) {
      // Fetch next API page
      widget.onNextPage!();
    }
  }

  bool get _canGoPrev => _currentPageIndex > 0 || widget.currentPage > 1;
  bool get _canGoNext {
    final totalLocalPages = (widget.items.length / 2).ceil();
    return _currentPageIndex < totalLocalPages - 1 || widget.hasMore;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nội dung liên quan', style: AppStyles.titleMedium),
            Row(
              children: [
                _buildNavButton(
                  icon: Icons.chevron_left,
                  onPressed: _canGoPrev ? _goToPreviousPage : null,
                ),
                const SizedBox(width: 8),
                _buildNavButton(
                  icon: Icons.chevron_right,
                  onPressed: _canGoNext ? _goToNextPage : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingM),

        // Content carousel
        if (widget.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPageIndex = index);
              },
              itemCount: (widget.items.length / 2).ceil(),
              itemBuilder: (context, pageIndex) {
                final startIndex = pageIndex * 2;
                final endIndex = (startIndex + 2).clamp(0, widget.items.length);
                final pageItems = widget.items.sublist(startIndex, endIndex);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: pageItems.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildCard(item),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

        // Page indicator
        if (widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppStyles.spacingS),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  (widget.items.length / 2).ceil(),
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentPageIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _currentPageIndex
                          ? AppColors.primary
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onPressed}) {
    final isEnabled = onPressed != null;
    return Material(
      color: isEnabled ? AppColors.primaryLight : AppColors.surfaceLight,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(RelatedContentItem item) {
    final isVideo = item.isVideo;

    return GestureDetector(
      onTap: () => widget.onItemTap(item),
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
                  if (item.thumbnailUrl != null)
                    Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[200]),
                    )
                  else
                    Container(color: Colors.grey[200]),
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
                  // Type badge
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
                    maxLines: 2,
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
