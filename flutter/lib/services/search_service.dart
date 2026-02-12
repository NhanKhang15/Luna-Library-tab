import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

/// Search result model matching backend
class SearchResultItem {
  final int id;
  final String type; // 'post' or 'video'
  final String title;
  final String? thumbnailUrl;
  final int viewCount;
  final int likeCount;
  final String authorName;

  SearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    this.thumbnailUrl,
    required this.viewCount,
    required this.likeCount,
    required this.authorName,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewCount: json['viewCount'] as int,
      likeCount: json['likeCount'] as int,
      authorName: json['authorName'] as String? ?? 'Chuyên gia',
    );
  }
}

class SearchResponse {
  final String query;
  final int total;
  final List<SearchResultItem> items;

  SearchResponse({
    required this.query,
    required this.total,
    required this.items,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] as String,
      total: json['total'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Service for Search API
class SearchService {
  final http.Client _client;

  SearchService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for posts and videos
  Future<SearchResponse> search(String query, {int limit = 20}) async {
    final uri = Uri.parse(
      '${ApiConfig.serviceBaseUrl}/api/search',
    ).replace(queryParameters: {'q': query, 'limit': limit.toString()});

    try {
      final response = await _client.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // Handle explicit UTF-8 decoding if needed, though http package usually handles it
        // If your backend returns a charset, http handles it.
        // If not, you might need decode: utf8.decode(response.bodyBytes)
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return SearchResponse.fromJson(json);
      } else {
        throw Exception(
          'Failed to search: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error during search: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
