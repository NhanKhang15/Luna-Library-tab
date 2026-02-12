import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_styles.dart';
import '../models/post.dart';
import '../models/video.dart';
import '../services/post_service.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';
import '../services/search_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/suggestion_dropdown.dart';
import '../widgets/category_chips.dart';
import '../widgets/content_toggle.dart';
import '../widgets/content_card.dart';
import '../widgets/video_card.dart';
import '../widgets/premium_banner.dart';
import '../widgets/floating_chat_button.dart';
import '../widgets/bottom_nav_bar.dart';
import 'post_detail_screen.dart';
import 'video_detail_screen.dart';
import 'chat_screen.dart';
import 'faq_screen.dart';

/// Main library screen that assembles all UI components
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  ContentType _selectedContentType = ContentType.videos;
  int _currentNavIndex = 1; // Thư viện tab
  String? _selectedTagName; // Selected tag for filtering

  // Scroll controller to preserve position
  final ScrollController _scrollController = ScrollController();

  // Search state
  final SearchService _searchService = SearchService();
  Timer? _searchDebounce;
  List<SearchResultItem> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchLoading = false;

  // Auth service and user ID
  final AuthService _authService = AuthService();
  int? _userId;

  // API services (initialized after getting user)
  late PostService _postService;
  late VideoService _videoService;
  bool _servicesInitialized = false;

  // Posts state
  List<PostListItem> _posts = [];
  bool _isLoadingPosts = true;
  String? _postsError;
  int _postsPage = 1;
  bool _hasMorePosts = true;

  // Videos state
  List<VideoListItem> _videos = [];
  bool _isLoadingVideos = true;
  String? _videosError;
  int _videosPage = 1;
  bool _hasMoreVideos = true;

  final List<PremiumBannerData> _banners = [
    const PremiumBannerData(
      id: '1',
      imageUrl:
          'https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?w=800',
      title: 'Khóa học Online',
      subtitle: 'Tham gia các khóa học chuyên sâu từ chuyên gia hàng đầu',
      icon: Icons.school,
    ),
    const PremiumBannerData(
      id: '2',
      imageUrl:
          'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=800',
      title: 'Nội dung Premium',
      subtitle:
          'Nâng cấp VIP để truy cập toàn bộ nội dung độc quyền không giới hạn',
      icon: Icons.diamond,
    ),
  ];

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
    _videoService = VideoService(userId: _userId);
    _servicesInitialized = true;
    _loadPosts();
    _loadVideos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchService.dispose();
    if (_servicesInitialized) {
      _postService.dispose();
      _videoService.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _isSearchLoading = true;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final response = await _searchService.search(query);
        if (mounted) {
          setState(() {
            _searchResults = response.items;
            _isSearchLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearchLoading = false);
        }
      }
    });
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _postsPage = 1;
        _posts = [];
        _hasMorePosts = true;
      });
    }

    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final response = await _postService.getPosts(
        page: _postsPage,
        pageSize: 10,
        sort: 'TRENDING',
        tagName: _selectedTagName,
      );

      setState(() {
        if (refresh || _postsPage == 1) {
          _posts = response.items;
        } else {
          _posts.addAll(response.items);
        }
        _hasMorePosts = response.hasMore;
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _postsError = e.toString();
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _videosPage = 1;
        _videos = [];
        _hasMoreVideos = true;
      });
    }

    setState(() {
      _isLoadingVideos = true;
      _videosError = null;
    });

    try {
      final response = await _videoService.getVideos(
        page: _videosPage,
        pageSize: 10,
        sort: 'TRENDING',
        tagName: _selectedTagName,
      );

      setState(() {
        if (refresh || _videosPage == 1) {
          _videos = response.items;
        } else {
          _videos.addAll(response.items);
        }
        _hasMoreVideos = response.hasMore;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _videosError = e.toString();
        _isLoadingVideos = false;
      });
    }
  }

  void _loadMorePosts() {
    if (!_isLoadingPosts && _hasMorePosts) {
      _postsPage++;
      _loadPosts();
    }
  }

  void _loadMoreVideos() {
    if (!_isLoadingVideos && _hasMoreVideos) {
      _videosPage++;
      _loadVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = 268;
    final double safeAreaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Pinned sticky header
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: headerHeight + safeAreaTop,
                  maxHeight: headerHeight + safeAreaTop,
                  child: Container(
                    color: AppColors.background,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Search bar (self-manages outer card + gradient) ──
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: SearchBarWidget(
                              onChanged: _onSearchChanged,
                              onHelpTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FAQScreen(),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Divider below search bar - Full width effect
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0x00E0E0E0), // Transparent start
                                  Color(0xFFE0E0E0), // Solid center
                                  Color(0x00E0E0E0), // Transparent end
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          const SuggestionDropdown(),
                          const SizedBox(height: 6),
                          CategoryChips(
                            selectedCategory: _selectedTagName,
                            onSelectionChanged: (tagName) {
                              setState(() => _selectedTagName = tagName);
                              _loadPosts(refresh: true);
                              _loadVideos(refresh: true);
                            },
                          ),
                          const SizedBox(height: 4),
                          ContentToggle(
                            selectedType: _selectedContentType,
                            onChanged: (type) =>
                                setState(() => _selectedContentType = type),
                          ),

                          // ✅ LINE FULL WIDTH cắt hết màn hình
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0x00000000),
                                  Color(0x26000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppStyles.spacingS),
              ),

              // Search results or normal content
              if (_isSearching)
                ..._buildSearchResults()
              else ...[
                // Content based on selection
                if (_selectedContentType == ContentType.articles)
                  ..._buildArticleCards()
                else
                  ..._buildVideoCards(),

                // Premium banner section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppStyles.spacingL,
                    ),
                    child: PremiumBanner(
                      banners: _banners,
                      onBannerTap: (index) {},
                    ),
                  ),
                ),

                // Load more button
                if (_selectedContentType == ContentType.articles &&
                    _hasMorePosts)
                  SliverToBoxAdapter(child: _buildLoadMoreButton(false))
                else if (_selectedContentType == ContentType.videos &&
                    _hasMoreVideos)
                  SliverToBoxAdapter(child: _buildLoadMoreButton(true)),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() => _currentNavIndex = index);
              },
            ),
          ),

          // Floating chat button on top of bottom nav
          FloatingChatButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildArticleCards() {
    if (_isLoadingPosts && _posts.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ];
    }

    if (_postsError != null && _posts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Không thể tải bài viết', style: AppStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _postsError!,
                    style: AppStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadPosts(refresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return _posts.map((post) {
      return SliverToBoxAdapter(
        child: ContentCard(
          data: ContentCardData(
            id: post.id.toString(),
            imageUrl:
                post.thumbnailUrl ??
                'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=800',
            title: post.title,
            viewCount: post.viewCount,
            likeCount: post.likeCount,
            authorName: post.expert?.fullName ?? 'Chuyên gia',
            isLiked: post.viewerState.liked,
            expertId: post.expert?.expertId,
          ),
          onTap: () {
            // Save scroll position before navigation
            final scrollPosition = _scrollController.offset;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(postId: post.id),
              ),
            ).then((_) {
              // Refresh posts when returning from detail screen
              _loadPosts(refresh: true).then((_) {
                // Restore scroll position after refresh
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(scrollPosition);
                }
              });
            });
          },
          onScheduleTap: () {},
        ),
      );
    }).toList();
  }

  List<Widget> _buildVideoCards() {
    if (_isLoadingVideos && _videos.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ];
    }

    if (_videosError != null && _videos.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Không thể tải video', style: AppStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _videosError!,
                    style: AppStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadVideos(refresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return _videos.map((video) {
      return SliverToBoxAdapter(
        child: VideoCard(
          data: VideoCardData(
            id: video.id.toString(),
            imageUrl:
                video.thumbnailUrl ??
                'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800',
            title: video.title,
            duration: video.duration,
            viewCount: video.viewCount,
            likeCount: video.likeCount,
            authorName: video.expert?.fullName ?? 'Chuyên gia',
            isLiked: video.viewerState.liked,
            expertId: video.expert?.expertId,
          ),
          onTap: () {
            // Save scroll position before navigation
            final scrollPosition = _scrollController.offset;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoDetailScreen(videoId: video.id),
              ),
            ).then((_) {
              // Refresh videos when returning from detail screen
              _loadVideos(refresh: true).then((_) {
                // Restore scroll position after refresh
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(scrollPosition);
                }
              });
            });
          },
          onScheduleTap: () {},
        ),
      );
    }).toList();
  }

  List<Widget> _buildSearchResults() {
    if (_isSearchLoading) {
      return [
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ];
    }

    if (_searchResults.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không tìm thấy kết quả nào'),
            ),
          ),
        ),
      ];
    }

    return _searchResults.map((item) {
      if (item.type == 'post') {
        return SliverToBoxAdapter(
          child: ContentCard(
            data: ContentCardData(
              id: item.id.toString(),
              imageUrl:
                  item.thumbnailUrl ??
                  'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=800',
              title: item.title,
              viewCount: item.viewCount,
              likeCount: item.likeCount,
              authorName: item.authorName,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: item.id),
                ),
              );
            },
          ),
        );
      } else {
        return SliverToBoxAdapter(
          child: VideoCard(
            data: VideoCardData(
              id: item.id.toString(),
              imageUrl:
                  item.thumbnailUrl ??
                  'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800',
              title: item.title,
              duration: '00:00',
              viewCount: item.viewCount,
              likeCount: item.likeCount,
              authorName: item.authorName,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(videoId: item.id),
                ),
              );
            },
          ),
        );
      }
    }).toList();
  }

  Widget _buildLoadMoreButton(bool isVideo) {
    final isLoading = isVideo ? _isLoadingVideos : _isLoadingPosts;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextButton(
        onPressed: isVideo ? _loadMoreVideos : _loadMorePosts,
        child: Text(isVideo ? 'Tải thêm video' : 'Tải thêm bài viết'),
      ),
    );
  }
}

/// Delegate for sticky header with fixed height
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
