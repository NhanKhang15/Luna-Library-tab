import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../core/app_styles.dart';
import '../core/url_utils.dart';
import '../models/video.dart';
import '../models/related_content.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';
import '../widgets/detail/gradient_header.dart';
import '../widgets/detail/author_card.dart';
import '../widgets/detail/info_box.dart';
import '../widgets/detail/related_content_carousel.dart';
import '../widgets/detail/video_player_widget.dart';
import 'post_detail_screen.dart';

class VideoDetailScreen extends StatefulWidget {
  final int videoId;

  const VideoDetailScreen({super.key, required this.videoId});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _playButtonController;
  late Animation<double> _playButtonScale;

  final AuthService _authService = AuthService();
  late VideoService _videoService;
  int? _userId;

  VideoDetail? _video;
  bool _isLoading = true;
  String? _error;
  bool _isVideoPlaying = true; // Auto-play video when entering screen

  // Like state (local copy for optimistic updates)
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  // Related content state
  List<RelatedContentItem> _relatedItems = [];
  int _relatedPage = 1;
  int _relatedTotalPages = 1;
  bool _relatedHasMore = false;
  bool _isRelatedLoading = false;

  @override
  void initState() {
    super.initState();
    _playButtonController = AnimationController(
      vsync: this,
      duration: AppStyles.animationNormal,
    );
    _playButtonScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );
    _initServices();
  }

  /// Initialize services with real user ID
  Future<void> _initServices() async {
    final user = await _authService.getCurrentUser();
    _userId = user?.id;
    _videoService = VideoService(userId: _userId);
    _loadVideoDetail();
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _videoService.dispose();
    super.dispose();
  }

  Future<void> _loadVideoDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final video = await _videoService.getVideoDetail(widget.videoId);
      setState(() {
        _video = video;
        _isLiked = video.viewerState.liked;
        _likeCount = video.likeCount;
        _isLoading = false;
      });
      // Load related content after video is loaded
      _loadRelatedContent();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load related content for current video
  Future<void> _loadRelatedContent({int page = 1}) async {
    if (_video == null) return;

    setState(() => _isRelatedLoading = true);

    try {
      final response = await _videoService.getRelatedContent(
        widget.videoId,
        page: page,
        pageSize: 6,
      );
      setState(() {
        _relatedItems = response.items;
        _relatedPage = response.page;
        _relatedTotalPages = response.totalPages;
        _relatedHasMore = response.hasMore;
        _isRelatedLoading = false;
      });
    } catch (e) {
      setState(() => _isRelatedLoading = false);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Toggle like with optimistic update and rollback on error
  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;

    // Optimistic update
    final previousLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLikeLoading = true;
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    try {
      final response = await _videoService.toggleLike(widget.videoId);
      // Sync with server response
      setState(() {
        _isLiked = response.liked;
        _likeCount = response.likeCount;
        _isLikeLoading = false;
      });
    } catch (e) {
      // Rollback on error
      setState(() {
        _isLiked = previousLiked;
        _likeCount = previousCount;
        _isLikeLoading = false;
      });
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể ${previousLiked ? "bỏ thích" : "thích"} video',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          GradientHeader(
            title: 'Video chuyên gia',
            subtitle: _video?.isShort == true ? 'Video ngắn' : 'Video',
            actionIcon: _isLiked ? Icons.favorite : Icons.favorite_border,
            actionIconColor: _isLiked ? Colors.pinkAccent : null,
            onActionTap: _video != null ? _toggleLike : null,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không thể tải video', style: AppStyles.titleMedium),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVideoDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final video = _video!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Hero Section or Video Player
            _isVideoPlaying
                ? VideoPlayerWidget(
                    videoUrl: video.videoUrl,
                    thumbnailUrl: video.thumbnailUrl,
                    autoPlay: true,
                  )
                : _buildVideoHero(video),

            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  _buildTags(video),
                  const SizedBox(height: AppStyles.spacingM),

                  // Title & Meta
                  Text(
                    video.title,
                    style: AppStyles.titleLarge.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                  _buildMetaRow(video),
                  const SizedBox(height: AppStyles.spacingL),

                  // Author Card
                  if (video.expert != null)
                    AuthorCard(
                      name: video.expert!.fullName,
                      role: video.expert!.specialization ?? 'Chuyên gia',
                      rating: 4.9,
                      ratingCount: 120,
                    ),
                  const SizedBox(height: AppStyles.spacingL),

                  // Video Player Section
                  _buildVideoPlayerSection(video),
                  const SizedBox(height: AppStyles.spacingL),

                  // Content Body
                  if (video.description != null &&
                      video.description!.isNotEmpty)
                    _buildContentBody(video.description!),

                  const SizedBox(height: AppStyles.spacingL),

                  // Info Boxes
                  const InfoBox(
                    type: InfoBoxType.author,
                    text:
                        'Tác giả: Quản trị viên • Chỉ Admin và Mod có quyền đăng bài',
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  const InfoBox(
                    type: InfoBoxType.notice,
                    text:
                        'Lưu ý: Nếu bạn muốn được tư vấn chuyên sâu hơn về chủ đề này, hãy đặt lịch tư vấn trực tiếp với chuyên gia của chúng tôi.',
                  ),
                  const SizedBox(height: AppStyles.spacingXL),

                  // Related Content (dynamic)
                  RelatedContentCarousel(
                    items: _relatedItems,
                    currentPage: _relatedPage,
                    totalPages: _relatedTotalPages,
                    hasMore: _relatedHasMore,
                    isLoading: _isRelatedLoading,
                    onItemTap: (item) {
                      if (item.isVideo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoDetailScreen(videoId: item.id),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(postId: item.id),
                          ),
                        );
                      }
                    },
                    onNextPage: _relatedHasMore
                        ? () => _loadRelatedContent(page: _relatedPage + 1)
                        : null,
                    onPreviousPage: _relatedPage > 1
                        ? () => _loadRelatedContent(page: _relatedPage - 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoHero(VideoDetail video) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppStyles.radiusXLarge),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (video.thumbnailUrl != null)
            Image.network(
              UrlUtils.convertForPlatform(video.thumbnailUrl!),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.video_library,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.video_library,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
          // Play Button Overlay
          MouseRegion(
            onEnter: (_) => _playButtonController.forward(),
            onExit: (_) => _playButtonController.reverse(),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isVideoPlaying = true;
                });
              },
              child: ScaleTransition(
                scale: _playButtonScale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: AppStyles.shadowMedium,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          // Duration Label
          Positioned(
            bottom: AppStyles.spacingM,
            right: AppStyles.spacingM,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              child: Text(
                video.duration,
                style: AppStyles.caption.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(VideoDetail video) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          video.isShort ? 'Video ngắn' : 'Video',
          icon: Icons.play_circle_outline,
        ),
        ...video.categories.map((cat) => _buildChip(cat, isOutline: true)),
      ],
    );
  }

  Widget _buildChip(String label, {IconData? icon, bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.white : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        border: isOutline
            ? Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(VideoDetail video) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_red_eye_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${_formatCount(video.viewCount)} lượt xem',
              style: AppStyles.caption,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(video.duration, style: AppStyles.caption),
          ],
        ),
        // Likes (uses local state for real-time update)
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: _isLiked ? Colors.pinkAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatCount(_likeCount)} lượt thích',
                style: AppStyles.caption.copyWith(
                  color: _isLiked ? Colors.pinkAccent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (video.publishedAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(_formatDate(video.publishedAt), style: AppStyles.caption),
            ],
          ),
      ],
    );
  }

  Widget _buildVideoPlayerSection(VideoDetail video) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.spacingM),
          Text(
            video.isShort ? 'Video Shorts Player' : 'Video Player',
            style: AppStyles.titleMedium,
          ),
          Text('Thời lượng: ${video.duration}', style: AppStyles.caption),
          const SizedBox(height: AppStyles.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(AppStyles.radiusPill),
            ),
            child: Text(
              video.isShort ? 'Full HD • Max 3 phút' : 'Full HD',
              style: AppStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBody(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mô tả', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          description,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
