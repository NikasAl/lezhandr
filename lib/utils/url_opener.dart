import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility class for opening URLs with fallback methods
class UrlOpener {
  static const MethodChannel _channel = MethodChannel('ru.kreagenium.lezhandr/url_opener');

  /// Open URL using native Android Intent or iOS UIApplication
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);

    // First try url_launcher
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      // Ignore, try native method
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

    // For iOS, try again with different mode
    if (Platform.isIOS) {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        return false;
      }
    }

    return false;
  }
}
