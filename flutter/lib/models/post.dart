/// Expert data model from API
class Expert {
  final int expertId;
  final String fullName;
  final String? specialization;

  Expert({required this.expertId, required this.fullName, this.specialization});

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      expertId: json['expertId'] as int,
      fullName: json['fullName'] as String,
      specialization: json['specialization'] as String?,
    );
  }
}

/// Viewer state for like/save status
class ViewerState {
  final bool liked;

  ViewerState({required this.liked});

  factory ViewerState.fromJson(Map<String, dynamic> json) {
    return ViewerState(liked: json['liked'] as bool? ?? false);
  }
}

/// Post list item from API
class PostListItem {
  final int id;
  final String title;
  final String? thumbnailUrl;
  final int viewCount;
  final int likeCount;
  final DateTime? publishedAt;
  final bool isPremium;
  final Expert? expert;
  final ViewerState viewerState;

  PostListItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.viewCount,
    required this.likeCount,
    this.publishedAt,
    required this.isPremium,
    this.expert,
    required this.viewerState,
  });

  factory PostListItem.fromJson(Map<String, dynamic> json) {
    return PostListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewCount: (json['viewCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
      expert: json['expert'] != null
          ? Expert.fromJson(json['expert'] as Map<String, dynamic>)
          : null,
      viewerState: json['viewerState'] != null
          ? ViewerState.fromJson(json['viewerState'] as Map<String, dynamic>)
          : ViewerState(liked: false),
    );
  }
}

/// Paginated posts response from API
class PostListResponse {
  final int page;
  final int pageSize;
  final int total;
  final List<PostListItem> items;

  PostListResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    return PostListResponse(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => PostListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => page * pageSize < total;
}

/// Post content for detail view
class PostContent {
  final String? summary;
  final String? body;

  PostContent({this.summary, this.body});

  factory PostContent.fromJson(Map<String, dynamic> json) {
    return PostContent(
      summary: json['summary'] as String?,
      body: json['body'] as String?,
    );
  }
}

/// Full post detail from API
class PostDetail {
  final int id;
  final String title;
  final String? thumbnailUrl;
  final List<String> categories;
  final DateTime? publishedAt;
  final int viewCount;
  final int likeCount;
  final bool isPremium;
  final Expert? expert;
  final PostContent content;
  final ViewerState viewerState;

  PostDetail({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.categories,
    this.publishedAt,
    required this.viewCount,
    required this.likeCount,
    required this.isPremium,
    this.expert,
    required this.content,
    required this.viewerState,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    return PostDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      viewCount: (json['viewCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
      isPremium: json['isPremium'] as bool? ?? false,
      expert: json['expert'] != null
          ? Expert.fromJson(json['expert'] as Map<String, dynamic>)
          : null,
      content: json['content'] != null
          ? PostContent.fromJson(json['content'] as Map<String, dynamic>)
          : PostContent(),
      viewerState: json['viewerState'] != null
          ? ViewerState.fromJson(json['viewerState'] as Map<String, dynamic>)
          : ViewerState(liked: false),
    );
  }
}
