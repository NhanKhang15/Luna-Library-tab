import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../core/app_styles.dart';
import '../core/url_utils.dart';
import '../models/post.dart';
import '../models/related_content.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../widgets/detail/gradient_header.dart';
import '../widgets/detail/author_card.dart';
import '../widgets/detail/info_box.dart';
import '../widgets/detail/related_content_carousel.dart';
import 'video_detail_screen.dart';
import 'consultant_detail_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final AuthService _authService = AuthService();
  late PostService _postService;
  int? _userId;

  PostDetail? _post;
  bool _isLoading = true;
  String? _error;

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
    _initServices();
  }

  /// Initialize services with real user ID
  Future<void> _initServices() async {
    final user = await _authService.getCurrentUser();
    _userId = user?.id;
    _postService = PostService(userId: _userId);
    _loadPostDetail();
  }

  @override
  void dispose() {
    _postService.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await _postService.getPostDetail(widget.postId);
      setState(() {
        _post = post;
        _isLiked = post.viewerState.liked;
        _likeCount = post.likeCount;
        _isLoading = false;
      });
      // Load related content after post is loaded
      _loadRelatedContent();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load related content for current post
  Future<void> _loadRelatedContent({int page = 1}) async {
    if (_post == null) return;

    setState(() => _isRelatedLoading = true);

    try {
      final response = await _postService.getRelatedContent(
        widget.postId,
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
      final response = await _postService.toggleLike(widget.postId);
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
              'Không thể ${previousLiked ? "bỏ thích" : "thích"} bài viết',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          GradientHeader(
            title: 'Bài viết nền tảng',
            subtitle: 'Bài viết',
            actionIcon: _isLiked ? Icons.favorite : Icons.favorite_border,
            actionIconColor: _isLiked ? Colors.pinkAccent : null,
            onActionTap: _post != null ? _toggleLike : null,
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
              Text('Không thể tải bài viết', style: AppStyles.titleMedium),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPostDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final post = _post!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                _buildHeroImage(post.thumbnailUrl),

                Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags (categories)
                      _buildTags(post.categories),
                      const SizedBox(height: AppStyles.spacingM),

                      // Title & Meta
                      Text(
                        post.title,
                        style: AppStyles.titleLarge.copyWith(height: 1.2),
                      ),
                      const SizedBox(height: AppStyles.spacingS),
                      _buildMetaRow(post),
                      const SizedBox(height: AppStyles.spacingL),

                      // Author Card
                      if (post.expert != null)
                        AuthorCard(
                          name: post.expert!.fullName,
                          role: post.expert!.specialization ?? 'Chuyên gia',
                          rating: 4.9,
                          ratingCount: 120,
                          onScheduleTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConsultantDetailScreen(
                                  expertId: post.expert!.expertId,
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: AppStyles.spacingL),

                      // Content Body
                      _buildContentBody(post.content),
                      const SizedBox(height: AppStyles.spacingL),

                      // Like Button (interactive)
                      _buildLikeButton(),
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
                            'Lưu ý: Nếu bạn muốn được tư vấn chuyên sâu hơn về chủ đề này, hãy đặt lịch tư vấn trực tiếp với chuyên gia của chúng tôi để nhận được giải pháp phù hợp nhất.',
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
                                builder: (_) =>
                                    VideoDetailScreen(videoId: item.id),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PostDetailScreen(postId: item.id),
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
        ),
      ),
    );
  }

  /// Interactive like button with pink heart
  Widget _buildLikeButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLikeLoading ? null : _toggleLike,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacingL,
              vertical: AppStyles.spacingM,
            ),
            decoration: BoxDecoration(
              color: _isLiked
                  ? Colors.pink.withOpacity(0.1)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(
                color: _isLiked ? Colors.pinkAccent : AppColors.borderLight,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isLiked),
                    color: _isLiked ? Colors.pinkAccent : AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isLiked ? 'Đã thích' : 'Thích bài viết',
                  style: AppStyles.bodyMedium.copyWith(
                    color: _isLiked ? Colors.pinkAccent : AppColors.textPrimary,
                    fontWeight: _isLiked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isLiked
                        ? Colors.pinkAccent.withOpacity(0.15)
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatCount(_likeCount),
                    style: AppStyles.caption.copyWith(
                      color: _isLiked
                          ? Colors.pinkAccent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isLikeLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String? imageUrl) {
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
      child: imageUrl != null
          ? Image.network(
              UrlUtils.convertForPlatform(imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                );
              },
            )
          : const Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
    );
  }

  Widget _buildTags(List<String> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip('Bài viết', icon: Icons.article_outlined),
        ...categories.map((cat) => _buildChip(cat, isOutline: true)),
      ],
    );
  }

  Widget _buildChip(String label, {IconData? icon, bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.white : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        border: isOutline
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
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

  Widget _buildMetaRow(PostDetail post) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        // Views
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
              '${_formatCount(post.viewCount)} lượt xem',
              style: AppStyles.caption,
            ),
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
        // Date
        if (post.publishedAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(_formatDate(post.publishedAt), style: AppStyles.caption),
            ],
          ),
      ],
    );
  }

  Widget _buildContentBody(PostContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.summary != null && content.summary!.isNotEmpty) ...[
          Text('Tổng quan', style: AppStyles.titleMedium),
          const SizedBox(height: AppStyles.spacingS),
          Text(
            content.summary!,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),
        ],
        if (content.body != null && content.body!.isNotEmpty) ...[
          Text('Nội dung', style: AppStyles.titleMedium),
          const SizedBox(height: AppStyles.spacingS),
          Text(
            content.body!,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}
