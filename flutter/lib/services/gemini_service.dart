import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

/// Service for communicating with the backend Gemini AI chat endpoint.
class GeminiService {
  final List<Map<String, String>> _history = [];

  List<Map<String, String>> get history => List.unmodifiable(_history);

  /// Send a message to the AI and return the reply.
  Future<String> sendMessage(String message) async {
    final url = Uri.parse('${ApiConfig.serviceBaseUrl}/chat/send');

    final body = jsonEncode({'message': message, 'history': _history});

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['reply'] as String;

      // Update conversation history
      _history.add({'role': 'user', 'text': message});
      _history.add({'role': 'model', 'text': reply});

      return reply;
    } else {
      throw Exception('Chat error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Clear conversation history.
  void clearHistory() {
    _history.clear();
  }

  void dispose() {
    _history.clear();
  }
}
