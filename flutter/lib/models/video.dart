/// Video list item from API
class VideoListItem {
  final int id;
  final String title;
  final String? thumbnailUrl;
  final String duration;
  final int viewCount;
  final int likeCount;
  final DateTime? publishedAt;
  final bool isPremium;
  final bool isShort;
  final VideoExpert? expert;
  final ViewerState viewerState;

  VideoListItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    this.publishedAt,
    required this.isPremium,
    required this.isShort,
    this.expert,
    required this.viewerState,
  });

  factory VideoListItem.fromJson(Map<String, dynamic> json) {
    return VideoListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: json['duration'] as String? ?? '0:00',
      viewCount: (json['viewCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
      isShort: json['isShort'] as bool? ?? false,
      expert: json['expert'] != null
          ? VideoExpert.fromJson(json['expert'] as Map<String, dynamic>)
          : null,
      viewerState: json['viewerState'] != null
          ? ViewerState.fromJson(json['viewerState'] as Map<String, dynamic>)
          : ViewerState(liked: false),
    );
  }
}

/// Expert data for video
class VideoExpert {
  final int expertId;
  final String fullName;
  final String? specialization;

  VideoExpert({
    required this.expertId,
    required this.fullName,
    this.specialization,
  });

  factory VideoExpert.fromJson(Map<String, dynamic> json) {
    return VideoExpert(
      expertId: json['expertId'] as int,
      fullName: json['fullName'] as String,
      specialization: json['specialization'] as String?,
    );
  }
}

/// Viewer state for like status
class ViewerState {
  final bool liked;

  ViewerState({required this.liked});

  factory ViewerState.fromJson(Map<String, dynamic> json) {
    return ViewerState(liked: json['liked'] as bool? ?? false);
  }
}

/// Paginated videos response from API
class VideoListResponse {
  final int page;
  final int pageSize;
  final int total;
  final List<VideoListItem> items;

  VideoListResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory VideoListResponse.fromJson(Map<String, dynamic> json) {
    return VideoListResponse(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => VideoListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => page * pageSize < total;
}

/// Full video detail from API
class VideoDetail {
  final int id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String videoUrl;
  final String duration;
  final int durationSeconds;
  final List<String> categories;
  final DateTime? publishedAt;
  final int viewCount;
  final int likeCount;
  final bool isPremium;
  final bool isShort;
  final VideoExpert? expert;
  final ViewerState viewerState;

  VideoDetail({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.durationSeconds,
    required this.categories,
    this.publishedAt,
    required this.viewCount,
    required this.likeCount,
    required this.isPremium,
    required this.isShort,
    this.expert,
    required this.viewerState,
  });

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    return VideoDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String,
      duration: json['duration'] as String? ?? '0:00',
      durationSeconds: (json['durationSeconds'] as num).toInt(),
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
      isShort: json['isShort'] as bool? ?? false,
      expert: json['expert'] != null
          ? VideoExpert.fromJson(json['expert'] as Map<String, dynamic>)
          : null,
      viewerState: json['viewerState'] != null
          ? ViewerState.fromJson(json['viewerState'] as Map<String, dynamic>)
          : ViewerState(liked: false),
    );
  }
}
