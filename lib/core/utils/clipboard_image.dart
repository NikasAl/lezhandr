import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Check if clipboard image paste is supported on current platform
///
/// Supported platforms: Web, Linux, macOS, Windows
/// Not supported: Android, iOS (limited clipboard access for images)
bool get isClipboardImageSupported {
  if (kIsWeb) return true;
  if (!kIsWeb && Platform.isLinux) return true;
  if (!kIsWeb && Platform.isMacOS) return true;
  if (!kIsWeb && Platform.isWindows) return true;
  return false; // Android, iOS
}

/// Result of clipboard image read operation
class ClipboardImageResult {
  final Uint8List? bytes;
  final String? filePath;
  final String? error;
  final String? format; // 'png', 'jpeg', etc.

  const ClipboardImageResult.success({
    required this.bytes,
    this.filePath,
    this.format,
  }) : error = null;

  const ClipboardImageResult.error(this.error)
      : bytes = null,
        filePath = null,
        format = null;

  bool get isSuccess => bytes != null;
}

/// Read image from system clipboard
///
/// Returns [ClipboardImageResult] with image bytes and optional temp file path.
/// On success, saves image to a temp file and returns both bytes and path.
/// On failure, returns error message.
Future<ClipboardImageResult> getImageFromClipboard() async {
  if (!isClipboardImageSupported) {
    return const ClipboardImageResult.error(
      'Буфер обмена не поддерживается на этой платформе',
    );
  }

  try {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return const ClipboardImageResult.error(
        'Не удалось получить доступ к буферу обмена',
      );
    }

    final reader = await clipboard.read();

    // Try different image formats
    final formats = reader.availableFormats;

    // Check for PNG
    if (formats.contains(Formats.png)) {
      final pngData = await reader.readFile(Formats.png);
      if (pngData != null) {
        return await _saveClipboardImage(pngData, 'png');
      }
    }

    // Check for JPEG
    if (formats.contains(Formats.jpeg)) {
      final jpegData = await reader.readFile(Formats.jpeg);
      if (jpegData != null) {
        return await _saveClipboardImage(jpegData, 'jpg');
      }
    }

    // Check for GIF
    if (formats.contains(Formats.gif)) {
      final gifData = await reader.readFile(Formats.gif);
      if (gifData != null) {
        return await _saveClipboardImage(gifData, 'gif');
      }
    }

    // Check for BMP
    if (formats.contains(Formats.bmp)) {
      final bmpData = await reader.readFile(Formats.bmp);
      if (bmpData != null) {
        return await _saveClipboardImage(bmpData, 'bmp');
      }
    }

    // Check for WebP
    if (formats.contains(Formats.webp)) {
      final webpData = await reader.readFile(Formats.webp);
      if (webpData != null) {
        return await _saveClipboardImage(webpData, 'webp');
      }
    }

    // No image format found
    return const ClipboardImageResult.error(
      'В буфере обмена нет изображения',
    );
  } catch (e) {
    return ClipboardImageResult.error('Ошибка чтения буфера: $e');
  }
}

/// Save clipboard image data to temp file and return result
Future<ClipboardImageResult> _saveClipboardImage(
  DataReader fileReader,
  String extension,
) async {
  try {
    // Read the image data
    final bytes = await fileReader.readAll();

    if (bytes == null || bytes.isEmpty) {
      return const ClipboardImageResult.error(
        'Не удалось прочитать данные изображения',
      );
    }

    // Create temp file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsBytes(bytes);

    return ClipboardImageResult.success(
      bytes: bytes,
      filePath: file.path,
      format: extension,
    );
  } catch (e) {
    return ClipboardImageResult.error('Ошибка сохранения изображения: $e');
  }
}

/// Check if clipboard contains an image without reading it
Future<bool> clipboardContainsImage() async {
  if (!isClipboardImageSupported) return false;

  try {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return false;

    final reader = await clipboard.read();
    final formats = reader.availableFormats;

    return formats.contains(Formats.png) ||
        formats.contains(Formats.jpeg) ||
        formats.contains(Formats.gif) ||
        formats.contains(Formats.bmp) ||
        formats.contains(Formats.webp);
  } catch (_) {
    return false;
  }
}
