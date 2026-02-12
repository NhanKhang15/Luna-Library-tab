import 'package:flutter/foundation.dart';

/// API configuration constants
class ApiConfig {
  // Change this to your backend URL
  // For Android emulator: use 10.0.2.2 instead of localhost
  // For iOS simulator: use localhost
  // For real device: use your computer's IP address

  // Platform-aware base URL
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:8000';
    return 'http://localhost:8000'; // iOS, Windows, macOS
  }

  static String get authBaseUrl {
    if (kIsWeb) return 'http://localhost:8001';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:8001';
    return 'http://localhost:8001';
  }

  static String get serviceBaseUrl {
    if (kIsWeb) return 'http://localhost:8002';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:8002';
    return 'http://localhost:8002';
  }

  // Content endpoints (Django)
  static const String postsEndpoint = '/api/v1/posts';
  static const String videosEndpoint = '/api/v1/videos';
  static const String expertsEndpoint = '/api/v1/experts';

  static const Duration timeout = Duration(seconds: 30);
}
