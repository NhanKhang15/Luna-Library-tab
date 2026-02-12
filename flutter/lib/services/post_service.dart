import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/post.dart';
import '../models/related_content.dart';

/// Response from like toggle
class LikeToggleResponse {
  final bool liked;
  final int likeCount;

  LikeToggleResponse({required this.liked, required this.likeCount});

  factory LikeToggleResponse.fromJson(Map<String, dynamic> json) {
    return LikeToggleResponse(
      liked: json['liked'] as bool,
      likeCount: (json['likeCount'] as num).toInt(),
    );
  }
}

/// Service for interacting with Posts API
class PostService {
  final http.Client _client;
  final int? userId;

  PostService({http.Client? client, this.userId})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (userId != null) {
      headers['X-User-Id'] = userId.toString();
    }
    return headers;
  }

  /// Fetch paginated list of posts
  Future<PostListResponse> getPosts({
    String? query,
    String? sort,
    int page = 1,
    int pageSize = 10,
    bool? premium,
    String? tagName,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (sort != null) {
      queryParams['sort'] = sort;
    }
    if (premium != null) {
      queryParams['premium'] = premium.toString();
    }
    if (tagName != null && tagName.isNotEmpty) {
      queryParams['tag'] = tagName;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.postsEndpoint}',
    ).replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PostListResponse.fromJson(json);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load posts: ${response.body}',
      );
    }
  }

  /// Fetch single post detail (also increments view count)
  Future<PostDetail> getPostDetail(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.postsEndpoint}/$id');

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PostDetail.fromJson(json);
    } else if (response.statusCode == 404) {
      throw PostNotFoundException(id);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load post: ${response.body}',
      );
    }
  }

  /// Toggle like on a post (like/unlike)
  Future<LikeToggleResponse> toggleLike(int postId) async {
    if (userId == null) {
      throw ApiException(statusCode: 401, message: 'User not authenticated');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.postsEndpoint}/$postId/like',
    );

    final response = await _client
        .post(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LikeToggleResponse.fromJson(json);
    } else if (response.statusCode == 404) {
      throw PostNotFoundException(postId);
    } else if (response.statusCode == 401) {
      throw ApiException(statusCode: 401, message: 'Authentication required');
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to toggle like: ${response.body}',
      );
    }
  }

  /// Fetch related content (posts and videos with same categories)
  Future<RelatedContentResponse> getRelatedContent(
    int postId, {
    int page = 1,
    int pageSize = 6,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.postsEndpoint}/$postId/related',
    ).replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RelatedContentResponse.fromJson(json);
    } else if (response.statusCode == 404) {
      throw PostNotFoundException(postId);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load related content: ${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// API exception
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Post not found exception
class PostNotFoundException implements Exception {
  final int postId;

  PostNotFoundException(this.postId);

  @override
  String toString() => 'Post with id $postId not found';
}
