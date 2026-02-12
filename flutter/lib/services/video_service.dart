import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/video.dart';
import '../models/related_content.dart';

/// Service for interacting with Videos API
class VideoService {
  final http.Client _client;
  final int? userId;

  VideoService({http.Client? client, this.userId})
    : _client = client ?? http.Client();

  /// Fetch paginated list of videos
  Future<VideoListResponse> getVideos({
    String? query,
    String? sort,
    int page = 1,
    int pageSize = 10,
    bool? premium,
    bool? isShort,
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
    if (isShort != null) {
      queryParams['isShort'] = isShort.toString();
    }
    if (tagName != null && tagName.isNotEmpty) {
      queryParams['tag'] = tagName;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/videos',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (userId != null) {
      headers['X-User-Id'] = userId.toString();
    }

    final response = await _client
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VideoListResponse.fromJson(json);
    } else {
      throw VideoApiException(
        statusCode: response.statusCode,
        message: 'Failed to load videos: ${response.body}',
      );
    }
  }

  /// Fetch single video detail (also increments view count)
  Future<VideoDetail> getVideoDetail(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/videos/$id');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (userId != null) {
      headers['X-User-Id'] = userId.toString();
    }

    final response = await _client
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VideoDetail.fromJson(json);
    } else if (response.statusCode == 404) {
      throw VideoNotFoundException(id);
    } else {
      throw VideoApiException(
        statusCode: response.statusCode,
        message: 'Failed to load video: ${response.body}',
      );
    }
  }

  /// Fetch related content (posts and videos with same categories)
  Future<RelatedContentResponse> getRelatedContent(
    int videoId, {
    int page = 1,
    int pageSize = 6,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/videos/$videoId/related',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (userId != null) {
      headers['X-User-Id'] = userId.toString();
    }

    final response = await _client
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RelatedContentResponse.fromJson(json);
    } else if (response.statusCode == 404) {
      throw VideoNotFoundException(videoId);
    } else {
      throw VideoApiException(
        statusCode: response.statusCode,
        message: 'Failed to load related content: ${response.body}',
      );
    }
  }

  /// Toggle like on a video (like/unlike)
  Future<VideoLikeToggleResponse> toggleLike(int videoId) async {
    if (userId == null) {
      throw VideoApiException(
        statusCode: 401,
        message: 'User not authenticated',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/videos/$videoId/like');

    final headers = <String, String>{'Content-Type': 'application/json'};
    headers['X-User-Id'] = userId.toString();

    final response = await _client
        .post(uri, headers: headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VideoLikeToggleResponse.fromJson(json);
    } else if (response.statusCode == 404) {
      throw VideoNotFoundException(videoId);
    } else if (response.statusCode == 401) {
      throw VideoApiException(
        statusCode: 401,
        message: 'Authentication required',
      );
    } else {
      throw VideoApiException(
        statusCode: response.statusCode,
        message: 'Failed to toggle like: ${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Response from video like toggle
class VideoLikeToggleResponse {
  final bool liked;
  final int likeCount;

  VideoLikeToggleResponse({required this.liked, required this.likeCount});

  factory VideoLikeToggleResponse.fromJson(Map<String, dynamic> json) {
    return VideoLikeToggleResponse(
      liked: json['liked'] as bool,
      likeCount: (json['likeCount'] as num).toInt(),
    );
  }
}

/// API exception
class VideoApiException implements Exception {
  final int statusCode;
  final String message;

  VideoApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'VideoApiException($statusCode): $message';
}

/// Video not found exception
class VideoNotFoundException implements Exception {
  final int videoId;

  VideoNotFoundException(this.videoId);

  @override
  String toString() => 'Video with id $videoId not found';
}
