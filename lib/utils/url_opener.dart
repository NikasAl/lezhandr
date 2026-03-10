import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility class for opening URLs with fallback methods
class UrlOpener {
  static const MethodChannel _channel = MethodChannel('ru.kreagenium.lezhandr/url_opener');

  /// Open URL using native Android Intent or iOS UIApplication
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);

    // For web platform, use url_launcher directly
    if (kIsWeb) {
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        return false;
      }
    }

    // First try url_launcher (works on Linux, macOS, Windows, iOS)
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      // Ignore, try native method for Android
    }

    // Fallback to native method channel for Android
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('openUrl', {'url': url});
        return result ?? false;
      } catch (e) {
        return false;
      }
    }

    // For other platforms (Linux, macOS, Windows, iOS), try platformDefault
    try {
      return await launchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}
