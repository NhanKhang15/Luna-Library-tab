import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/consultant.dart';

/// Service for interacting with Experts API
class ExpertService {
  final http.Client _client;

  ExpertService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  /// Fetch paginated list of experts
  Future<ExpertListResponse> getExperts({
    String? query,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.expertsEndpoint}',
    ).replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ExpertListResponse.fromJson(json);
    } else {
      throw ExpertApiException(
        statusCode: response.statusCode,
        message: 'Failed to load experts: ${response.body}',
      );
    }
  }

  /// Fetch single expert detail
  Future<Consultant> getExpertDetail(int expertId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.expertsEndpoint}/$expertId/',
    );

    print('ExpertService: fetching detail for $expertId');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    print(
      'ExpertService: status=${response.statusCode}, body=${response.body}',
    );

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Consultant.fromJson(json);
      } catch (e) {
        print('ExpertService: JSON parse error: $e');
        rethrow;
      }
    } else if (response.statusCode == 404) {
      throw ExpertNotFoundException(expertId);
    } else {
      throw ExpertApiException(
        statusCode: response.statusCode,
        message: 'Failed to load expert: ${response.body}',
      );
    }
  }

  /// Fetch paginated reviews for an expert
  Future<ExpertReviewListResponse> getExpertReviews(
    int expertId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.expertsEndpoint}/$expertId/reviews/',
    ).replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ExpertReviewListResponse.fromJson(json);
    } else {
      throw ExpertApiException(
        statusCode: response.statusCode,
        message: 'Failed to load reviews: ${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Paginated response for expert list
class ExpertListResponse {
  final int page;
  final int pageSize;
  final int total;
  final List<Consultant> items;

  ExpertListResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory ExpertListResponse.fromJson(Map<String, dynamic> json) {
    return ExpertListResponse(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
      items: (json['items'] as List)
          .map((e) => Consultant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Paginated response for expert reviews
class ExpertReviewListResponse {
  final int page;
  final int pageSize;
  final int total;
  final List<ExpertReview> items;

  ExpertReviewListResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  bool get hasMore => total > page * pageSize;

  factory ExpertReviewListResponse.fromJson(Map<String, dynamic> json) {
    return ExpertReviewListResponse(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
      items: (json['items'] as List)
          .map((e) => ExpertReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// API exception for expert endpoints
class ExpertApiException implements Exception {
  final int statusCode;
  final String message;

  ExpertApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ExpertApiException($statusCode): $message';
}

/// Expert not found exception
class ExpertNotFoundException implements Exception {
  final int expertId;

  ExpertNotFoundException(this.expertId);

  @override
  String toString() => 'Expert with id $expertId not found';
}
