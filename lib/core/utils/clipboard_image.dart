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
    final imageFormats = <(DataFormat<DataReader>, String)>[
      (Formats.png, 'png'),
      (Formats.jpeg, 'jpg'),
      (Formats.webp, 'webp'),
      (Formats.gif, 'gif'),
      (Formats.bmp, 'bmp'),
    ];

    for (final (format, ext) in imageFormats) {
      if (reader.canProvideValue(format)) {
        final result = await _tryReadFormat(reader, format, ext);
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

/// Try to read a specific format from clipboard
Future<ClipboardImageResult?> _tryReadFormat(
  ClipboardReader reader,
  DataFormat<DataReader> format,
  String extension,
) async {
  try {
    // Get the data reader for this format
    final dataReader = await reader.readValue(format);
    if (dataReader == null) return null;

    // Create temp file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${tempDir.path}/$fileName');

    // Use a completer to handle async file writing
    final completer = Completer<ClipboardImageResult?>();
    
    // Try to read the file data
    // Note: super_clipboard API uses getFile for binary data
    dataReader.getFile(
      format,
      (Stream<List<int>> stream) async {
        try {
          // Write the binary stream to file
          final sink = file.openWrite();
          await sink.addStream(stream);
          await sink.close();

          // Verify file was written
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              if (!completer.isCompleted) {
                completer.complete(ClipboardImageResult.success(
                  bytes: bytes,
                  filePath: file.path,
                  format: extension,
                ));
              }
              return true;
            }
          }
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return false;
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return false;
        }
      },
      onError: (String error) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return false;
      },
    );

    // Wait for the result with a timeout
    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  } catch (e) {
    return null;
  }
}

/// Check if clipboard contains an image without reading it
Future<bool> clipboardContainsImage() async {
  if (!isClipboardImageSupported) return false;

  try {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return false;

    final reader = await clipboard.read();

    return reader.canProvideValue(Formats.png) ||
        reader.canProvideValue(Formats.jpeg) ||
        reader.canProvideValue(Formats.gif) ||
        reader.canProvideValue(Formats.webp) ||
        reader.canProvideValue(Formats.bmp);
  } catch (_) {
    return false;
  }
}
