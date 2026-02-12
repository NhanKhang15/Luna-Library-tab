import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_styles.dart';
import '../models/consultant.dart';
import '../services/expert_service.dart';
import '../widgets/consultant/stats_card.dart';
import '../widgets/consultant/specialty_tags.dart';
import '../widgets/consultant/info_section.dart';
import '../widgets/bottom_nav_bar.dart';

class ConsultantDetailScreen extends StatefulWidget {
  final Consultant? consultant;
  final int? expertId;

  const ConsultantDetailScreen({super.key, this.consultant, this.expertId});

  @override
  State<ConsultantDetailScreen> createState() => _ConsultantDetailScreenState();
}

class _ConsultantDetailScreenState extends State<ConsultantDetailScreen> {
  Consultant? _consultant;
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;
  final ExpertService _expertService = ExpertService();

  // Reviews state
  List<ExpertReview> _reviews = [];
  bool _isLoadingReviews = true;
  int _reviewsPage = 1;
  bool _hasMoreReviews = true;

  Future<void> _loadReviews({bool refresh = false}) async {
    final id = widget.expertId ?? widget.consultant?.id;
    if (id == null) return;

    if (refresh) {
      if (mounted) {
        setState(() {
          _reviewsPage = 1;
          _reviews = [];
          _hasMoreReviews = true;
        });
      }
    }

    if (mounted) setState(() => _isLoadingReviews = true);

    try {
      final response = await _expertService.getExpertReviews(
        id,
        page: _reviewsPage,
      );
      if (mounted) {
        setState(() {
          if (refresh || _reviewsPage == 1) {
            _reviews = response.items;
          } else {
            _reviews.addAll(response.items);
          }
          _hasMoreReviews = response.hasMore;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void initState() {
    super.initState();
    print(
      'ConsultantDetailScreen init: expertId=${widget.expertId}, consultant=${widget.consultant?.id}',
    );
    if (widget.consultant != null) {
      _consultant = widget.consultant;
      _isLoading = false;
      _loadReviews();
    } else if (widget.expertId != null) {
      _fetchExpertDetail();
      _loadReviews();
    } else {
      _isLoading = false;
      _error = 'Không tìm thấy thông tin chuyên gia (ID is null)';
    }
  }

  Future<void> _fetchExpertDetail() async {
    try {
      final expert = await _expertService.getExpertDetail(widget.expertId!);
      if (mounted) {
        setState(() {
          _consultant = expert;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ConsultantDetailScreen: error loading expert: $e');
      if (mounted) {
        setState(() {
          _error = 'Không thể tải thông tin chuyên gia: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _expertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppStyles.spacingM),
                    Text(
                      _error!,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingL),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _fetchExpertDetail();
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildProfileWithStats()),
                  SliverToBoxAdapter(child: _buildActionButtons()),
                  SliverToBoxAdapter(child: _buildInfoSections()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppStyles.spacingXXL),
                  ),
                ],
              ),
            ),
          const BottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  /// Separate back button row at top (outside gradient)
  Widget _buildTopBar() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingL,
            vertical: AppStyles.spacingS,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppStyles.spacingXS),
                    Text(
                      'Quay lại',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile header with overlapping stats cards
  Widget _buildProfileWithStats() {
    final consultant = _consultant!;
    const double statsOverlap = 40;
    final double horizontalPadding = MediaQuery.of(context).size.width * 0.085;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: AppStyles.spacingL,
            right: AppStyles.spacingL,
            bottom: statsOverlap,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppStyles.spacingL,
              bottom: statsOverlap + AppStyles.spacingL,
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: consultant.avatarUrl != null
                            ? Image.network(
                                consultant.avatarUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFFF5E6D3),
                                child: Center(
                                  child: Text(
                                    consultant.name.isNotEmpty
                                        ? consultant.name[0].toUpperCase()
                                        : '?',
                                    style: AppStyles.headlineLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (consultant.isVerified)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingM),
                Text(
                  consultant.name,
                  style: AppStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingXS),
                Text(
                  consultant.title,
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacingL,
                    vertical: AppStyles.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                  ),
                  child: Text(
                    consultant.primaryTag,
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < consultant.rating.floor()
                            ? Colors.amber
                            : Colors.amber.withOpacity(0.3),
                        size: 20,
                      );
                    }),
                    const SizedBox(width: AppStyles.spacingS),
                    Text(
                      '(${consultant.rating} - ${consultant.ratingCount} đánh giá)',
                      style: AppStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingL),
              ],
            ),
          ),
        ),
        Positioned(
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: 0,
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Kinh nghiệm',
                  value: '${consultant.yearsExperience} năm',
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: StatsCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Buổi tư vấn',
                  value: '${consultant.consultationCount}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppStyles.spacingL,
        right: AppStyles.spacingL,
        top: AppStyles.spacingL,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to booking screen
                  },
                  borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppStyles.spacingS),
                      Text(
                        'Đặt lịch',
                        style: AppStyles.button.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            flex: 1,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                border: Border.all(color: AppColors.borderLight, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isFollowing
                            ? Icons.person_remove_outlined
                            : Icons.person_add_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppStyles.spacingXS),
                      Text(
                        'Follow',
                        style: AppStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSections() {
    final consultant = _consultant!;
    return Column(
      children: [
        const SizedBox(height: AppStyles.spacingL),
        InfoSection(
          title: 'Giới thiệu',
          child: Text(
            consultant.bio,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: AppStyles.spacingM),
        InfoSection(
          title: 'Lĩnh vực chuyên môn',
          child: SpecialtyTags(specialties: consultant.specialties),
        ),
        const SizedBox(height: AppStyles.spacingM),
        InfoSection(
          title: 'Giá tư vấn',
          child: Text(
            consultant.priceInfo,
            style: AppStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppStyles.spacingL),
        _buildReviewsSection(),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingL),
          child: Text(
            'Đánh giá từ học viên',
            style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppStyles.spacingM),
        if (_isLoadingReviews && _reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingL),
            child: Text(
              'Chưa có đánh giá nào.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ..._reviews.map((review) => _buildReviewItem(review)),

        if (_reviews.isNotEmpty && _hasMoreReviews)
          Padding(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            child: Center(
              child: TextButton(
                onPressed: () {
                  _reviewsPage++;
                  _loadReviews();
                },
                child: _isLoadingReviews
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xem thêm đánh giá'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewItem(ExpertReview review) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: AppStyles.spacingM,
        left: AppStyles.spacingL,
        right: AppStyles.spacingL,
      ),
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  'U',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người dùng #${review.userId}',
                      style: AppStyles.labelMedium,
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 14,
                          color: index < review.rating
                              ? Colors.amber
                              : AppColors.borderLight,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacingS),
            Text(
              review.comment!,
              style: AppStyles.bodyMedium.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
