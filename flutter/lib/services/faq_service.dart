import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/api_config.dart';
import '../models/faq_model.dart';
import '../services/auth_service.dart';

class FAQService {
  static Future<List<FAQItem>> getFAQs(String category) async {
    // Map UI category names to API slugs
    String categorySlug;
    switch (category) {
      case 'Tâm lý':
        categorySlug = 'tam-ly';
        break;
      case 'Sinh học':
        categorySlug = 'sinh-hoc';
        break;
      case 'Pháp lý':
        categorySlug = 'phap-ly';
        break;
      default:
        categorySlug = 'tam-ly';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/faqs/?category=$categorySlug',
    );

    // Get token if available
    final token = await AuthService().getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((e) => FAQItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      // Return empty list instead of crashing, or rethrow if preferred
      return [];
    }
  }
}
