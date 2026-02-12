import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/app_colors.dart';
import '../core/app_styles.dart';

/// Premium banner data model
class PremiumBannerData {
  final String id;
  final String imageUrl;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const PremiumBannerData({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

/// Auto-sliding premium banner widget with PageView
/// Features: hover effect, prev/next navigation buttons, infinite loop, no peek
class PremiumBanner extends StatefulWidget {
  final List<PremiumBannerData> banners;
  final Duration autoScrollDuration;
  final ValueChanged<int>? onBannerTap;

  const PremiumBanner({
    super.key,
    required this.banners,
    this.autoScrollDuration = const Duration(seconds: 4),
    this.onBannerTap,
  });

  @override
  State<PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<PremiumBanner> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _isHovered = false;
  bool _hasMouseConnected = false;

  bool get _isPointerDevice => kIsWeb || _hasMouseConnected;

  @override
  void initState() {
    super.initState();
    // viewportFraction = 1.0 to show exactly one full page (no peek)
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (_pageController.hasClients && !_isHovered) {
        _goToNextPage();
      }
    });
  }

  void _goToNextPage() {
    final nextPage = (_currentPage + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    final prevPage =
        (_currentPage - 1 + widget.banners.length) % widget.banners.length;
    _pageController.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect if mouse is connected
    final mouseConnected =
        WidgetsBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseConnected != _hasMouseConnected) {
      _hasMouseConnected = mouseConnected;
    }

    return Column(
      children: [
        // Banner with navigation
        MouseRegion(
          onEnter: _isPointerDevice
              ? (_) => setState(() => _isHovered = true)
              : null,
          onExit: _isPointerDevice
              ? (_) => setState(() => _isHovered = false)
              : null,
          child: AnimatedScale(
            scale: _isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.fastOutSlowIn,
            child: SizedBox(
              height: 140,
              child: Stack(
                children: [
                  // PageView (no peek: viewportFraction = 1.0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: widget.banners.length,
                      clipBehavior: Clip.hardEdge,
                      itemBuilder: (context, index) {
                        return _BannerItem(
                          data: widget.banners[index],
                          onTap: () => widget.onBannerTap?.call(index),
                        );
                      },
                    ),
                  ),

                  // Previous button (left)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavButton(
                        icon: Icons.chevron_left,
                        onTap: _goToPreviousPage,
                        isVisible: widget.banners.length > 1,
                      ),
                    ),
                  ),

                  // Next button (right)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavButton(
                        icon: Icons.chevron_right,
                        onTap: _goToNextPage,
                        isVisible: widget.banners.length > 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppStyles.spacingM),

        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primary
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Navigation button for carousel
class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isVisible;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.isVisible = true,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.95)
                : Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(widget.icon, color: AppColors.primary, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Single banner item
class _BannerItem extends StatelessWidget {
  final PremiumBannerData data;
  final VoidCallback? onTap;

  const _BannerItem({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Remove horizontal margin to eliminate peek
        margin: const EdgeInsets.symmetric(horizontal: AppStyles.spacingL),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          boxShadow: AppStyles.shadowLight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Text content
              Positioned(
                left: AppStyles.spacingL,
                right: AppStyles.spacingL,
                bottom: AppStyles.spacingL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.title,
                          style: AppStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (data.icon != null) ...[
                          const SizedBox(width: AppStyles.spacingS),
                          Icon(data.icon, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                    if (data.subtitle != null) ...[
                      const SizedBox(height: AppStyles.spacingXS),
                      Text(
                        data.subtitle!,
                        style: AppStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
