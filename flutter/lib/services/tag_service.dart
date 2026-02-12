import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

/// Tag model
class Tag {
  final int id;
  final String name;
  final String slug;

  const Tag({required this.id, required this.name, required this.slug});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

/// Service for fetching tags from API
class TagService {
  final http.Client _client;

  TagService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all available tags
  Future<List<Tag>> getTags() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/tags');

    final response = await _client
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final items = json['items'] as List;
      return items
          .map((item) => Tag.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw TagApiException(
        statusCode: response.statusCode,
        message: 'Failed to load tags: ${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Tag API exception
class TagApiException implements Exception {
  final int statusCode;
  final String message;

  TagApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'TagApiException($statusCode): $message';
}
