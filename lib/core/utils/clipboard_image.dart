import 'dart:async';
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

    // List of image formats to try (in order of preference)
    final imageFormats = <(FileFormat, String)>[
      (Formats.png, 'png'),
      (Formats.jpeg, 'jpg'),
      (Formats.webp, 'webp'),
      (Formats.gif, 'gif'),
      (Formats.bmp, 'bmp'),
    ];

    for (final (format, ext) in imageFormats) {
      if (reader.canProvide(format)) {
        final result = await _tryReadFileFormat(reader, format, ext);
        if (result != null) {
          return result;
        }
      }
    }

    // No image format found
    return const ClipboardImageResult.error(
      'В буфере обмена нет изображения.\n\n'
      'Поддерживаемые форматы: PNG, JPEG, WebP, GIF, BMP.\n\n'
      'Совет: Скопируйте изображение (скриншот или Ctrl+C на картинке в браузере).',
    );
  } catch (e) {
    return ClipboardImageResult.error('Ошибка чтения буфера: $e');
  }
}

/// Try to read a specific file format from clipboard
Future<ClipboardImageResult?> _tryReadFileFormat(
  ClipboardReader reader,
  FileFormat format,
  String extension,
) async {
  final completer = Completer<ClipboardImageResult?>();
  
  reader.getFile(
    format,
    (DataReaderFile file) async {
      try {
        // Read all file data
        final bytes = await file.readAll();
        
        if (bytes.isNotEmpty) {
          // Create temp file
          final tempDir = await getTemporaryDirectory();
          final fileName = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final outputFile = File('${tempDir.path}/$fileName');
          
          await outputFile.writeAsBytes(bytes);
          
          if (!completer.isCompleted) {
            completer.complete(ClipboardImageResult.success(
              bytes: bytes,
              filePath: outputFile.path,
              format: extension,
            ));
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    },
    onError: (error) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
  );

  // Wait for the result with a timeout
  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => null,
  );
}

/// Check if clipboard contains an image without reading it
Future<bool> clipboardContainsImage() async {
  if (!isClipboardImageSupported) return false;

  try {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return false;

    final reader = await clipboard.read();

    return reader.canProvide(Formats.png) ||
        reader.canProvide(Formats.jpeg) ||
        reader.canProvide(Formats.gif) ||
        reader.canProvide(Formats.webp) ||
        reader.canProvide(Formats.bmp);
  } catch (_) {
    return false;
  }
}
