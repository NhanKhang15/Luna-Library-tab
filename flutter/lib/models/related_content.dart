/// Related content item from API
class RelatedContentItem {
  final int id;
  final String type; // 'post' or 'video'
  final String title;
  final String? thumbnailUrl;

  RelatedContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.thumbnailUrl,
  });

  factory RelatedContentItem.fromJson(Map<String, dynamic> json) {
    return RelatedContentItem(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  bool get isVideo => type == 'video';
  bool get isPost => type == 'post';
}

/// Paginated response for related content
class RelatedContentResponse {
  final int page;
  final int pageSize;
  final int total;
  final List<RelatedContentItem> items;

  RelatedContentResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory RelatedContentResponse.fromJson(Map<String, dynamic> json) {
    return RelatedContentResponse(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => RelatedContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => page * pageSize < total;
  int get totalPages => (total / pageSize).ceil();
}
