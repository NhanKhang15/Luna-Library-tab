import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for URL handling across the app.
class UrlUtils {
  /// Convert localhost URLs to 10.0.2.2 for Android emulator.
  /// On Android emulator, localhost refers to the emulator itself,
  /// so we need to use 10.0.2.2 to access the host machine.
  ///
  /// This handles both http and https URLs with localhost or 127.0.0.1.
  static String convertForPlatform(String url) {
    if (kIsWeb) return url;

    if (Platform.isAndroid) {
      // Replace localhost or 127.0.0.1 with 10.0.2.2 for Android emulator
      return url
          .replaceFirst('http://localhost', 'http://10.0.2.2')
          .replaceFirst('http://127.0.0.1', 'http://10.0.2.2')
          .replaceFirst('https://localhost', 'https://10.0.2.2')
          .replaceFirst('https://127.0.0.1', 'https://10.0.2.2');
    }

    return url;
  }

  /// Convert URL if not null, returns null if input is null.
  static String? convertForPlatformNullable(String? url) {
    if (url == null) return null;
    return convertForPlatform(url);
  }
}
