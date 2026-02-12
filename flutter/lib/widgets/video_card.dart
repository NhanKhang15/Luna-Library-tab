import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/app_colors.dart';
import '../core/app_styles.dart';
import '../core/url_utils.dart';
import '../screens/consultant_detail_screen.dart';

/// Video card data model
class VideoCardData {
  final String id;
  final String imageUrl;
  final String title;
  final String label;
  final String duration;
  final int viewCount;
  final int likeCount;
  final String authorName;
  final String? authorAvatarUrl;
  final bool isLiked;

  const VideoCardData({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.label = 'Video ngắn',
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    required this.authorName,
    this.authorAvatarUrl,
    this.isLiked = false,
    this.expertId,
  });

  final int? expertId;
}

/// Video content card widget matching Figma design
class VideoCard extends StatefulWidget {
  final VideoCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onScheduleTap;

  const VideoCard({
    super.key,
    required this.data,
    this.onTap,
    this.onScheduleTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _hasMouseConnected = false;
  late AnimationController _playButtonController;
  late Animation<double> _playButtonScale;

  bool get _isPointerDevice => kIsWeb || _hasMouseConnected;

  // Figma colors
  static const Color _cardBg = Colors.white;
  static const Color _titleColor = Color(0xFF2D2D2D);
  static const Color _statsColor = Color(0xFF999999);
  static const Color _authorColor = Color(0xFF666666);
  static const Color _badgeBg = Color(0xFF8B5CF6); // Purple badge
  static const Color _likedColor = Color(0xFFE75A9D);

  // Figma gradient for button
  static const LinearGradient _buttonGradient = LinearGradient(
    colors: [Color(0xFFE75A9D), Color(0xFFC86DD7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _playButtonScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _playButtonController,
        curve: Curves.fastOutSlowIn,
      ),
    );
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final mouseConnected =
        WidgetsBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseConnected != _hasMouseConnected) {
      _hasMouseConnected = mouseConnected;
    }

    return MouseRegion(
      onEnter: _isPointerDevice
          ? (_) {
              setState(() => _isHovered = true);
              _playButtonController.forward();
            }
          : null,
      onExit: _isPointerDevice
          ? (_) {
              setState(() => _isHovered = false);
              _playButtonController.reverse();
            }
          : null,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.fastOutSlowIn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.fastOutSlowIn,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildVideoThumbnail(), _buildContentSection()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              UrlUtils.convertForPlatform(widget.data.imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      size: 48,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Play button overlay
        ScaleTransition(
          scale: _playButtonScale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: AppStyles.shadowMedium,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
        ),
        // Video badge (top-left)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _badgeBg.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.data.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Duration label (bottom-right)
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.data.duration,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _titleColor,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 14),
          _buildAuthorRow(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Icon(Icons.visibility_outlined, size: 15, color: _statsColor),
        const SizedBox(width: 6),
        Text(
          _formatCount(widget.data.viewCount),
          style: const TextStyle(fontSize: 13, color: _statsColor),
        ),
        const SizedBox(width: 16),
        Icon(
          widget.data.isLiked ? Icons.favorite : Icons.favorite_outline,
          size: 15,
          color: widget.data.isLiked ? _likedColor : _statsColor,
        ),
        const SizedBox(width: 6),
        Text(
          _formatCount(widget.data.likeCount),
          style: TextStyle(
            fontSize: 13,
            color: widget.data.isLiked ? _likedColor : _statsColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFF0F0F0),
          backgroundImage: widget.data.authorAvatarUrl != null
              ? NetworkImage(widget.data.authorAvatarUrl!)
              : null,
          child: widget.data.authorAvatarUrl == null
              ? Text(
                  widget.data.authorName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.data.authorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _authorColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star, size: 14, color: Colors.amber[600]),
            ],
          ),
        ),
        _buildScheduleButton(),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ConsultantDetailScreen(expertId: widget.data.expertId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: _buttonGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE75A9D).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Text(
            'Đặt lịch',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
