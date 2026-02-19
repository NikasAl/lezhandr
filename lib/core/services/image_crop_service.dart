import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Result of crop operation
class CropResult {
  final String filePath;
  final int width;
  final int height;

  CropResult({
    required this.filePath,
    required this.width,
    required this.height,
  });
}

/// Service for cropping images
class ImageCropService {
  /// Crop image from file and save to new file
  /// 
  /// [imagePath] - path to original image
  /// [cropRect] - normalized rect (0.0-1.0) relative to image dimensions
  static Future<CropResult> cropImage({
    required String imagePath,
    required Rect cropRect,
  }) async {
    // Load original image
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    
    // Decode image
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Calculate actual crop dimensions
    final int x = (cropRect.left * originalImage.width).round();
    final int y = (cropRect.top * originalImage.height).round();
    final int width = (cropRect.width * originalImage.width).round();
    final int height = (cropRect.height * originalImage.height).round();

    // Ensure bounds are valid
    final int clampedX = x.clamp(0, originalImage.width - 1);
    final int clampedY = y.clamp(0, originalImage.height - 1);
    final int clampedWidth = width.clamp(1, originalImage.width - clampedX);
    final int clampedHeight = height.clamp(1, originalImage.height - clampedY);

    // Crop the image
    final croppedImage = img.copyCrop(
      originalImage,
      x: clampedX,
      y: clampedY,
      width: clampedWidth,
      height: clampedHeight,
    );

    // Encode to JPEG
    final croppedBytes = img.encodeJpg(croppedImage, quality: 90);

    // Save to new file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${p.basenameWithoutExtension(imagePath)}_cropped_$timestamp.jpg';
    final newPath = p.join(directory.path, fileName);

    final newFile = File(newPath);
    await newFile.writeAsBytes(croppedBytes);

    return CropResult(
      filePath: newPath,
      width: clampedWidth,
      height: clampedHeight,
    );
  }

  /// Get image dimensions without loading full image
  static Future<Size> getImageSize(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    
    final size = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    
    image.dispose();
    return size;
  }
}
