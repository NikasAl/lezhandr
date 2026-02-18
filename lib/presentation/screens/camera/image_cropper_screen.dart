import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/services/image_crop_service.dart';

/// Screen for cropping an image
/// Returns the path to cropped image file, or null if cancelled
class ImageCropperScreen extends StatefulWidget {
  final String imagePath;
  final String? title;

  const ImageCropperScreen({
    super.key,
    required this.imagePath,
    this.title,
  });

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  final TransformationController _transformController = TransformationController();
  
  Rect _cropRect = Rect.zero;
  Size _imageSize = Size.zero;
  Size _displaySize = Size.zero;
  Offset _imageOffset = Offset.zero;
  
  int? _activeCorner; // 0=tl, 1=tr, 2=br, 3=bl
  Offset? _dragStart;
  Rect? _dragStartRect;
  
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final size = await ImageCropService.getImageSize(widget.imagePath);
    setState(() {
      _imageSize = size;
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Initialize crop rect when widget dimensions are known
  void _initCropRect() {
    if (_cropRect != Rect.zero || _displaySize == Size.zero) return;
    
    // Vertical rectangle in center (2:3 aspect ratio)
    final double aspectRatio = 2.0 / 3.0;
    final double rectWidth = _displaySize.width * 0.8;
    final double rectHeight = rectWidth / aspectRatio;
    
    // Clamp height to fit in display
    final double clampedHeight = rectHeight.clamp(
      _displaySize.height * 0.3,
      _displaySize.height * 0.85,
    );
    final double clampedWidth = clampedHeight * aspectRatio;
    
    setState(() {
      _cropRect = Rect.fromCenter(
        center: Offset(_displaySize.width / 2, _displaySize.height / 2),
        width: clampedWidth,
        height: clampedHeight,
      );
    });
  }

  /// Convert display rect to normalized rect (0.0-1.0)
  Rect _toNormalizedRect(Rect displayRect) {
    return Rect.fromLTRB(
      (displayRect.left - _imageOffset.dx) / _displaySize.width,
      (displayRect.top - _imageOffset.dy) / _displaySize.height,
      (displayRect.right - _imageOffset.dx) / _displaySize.width,
      (displayRect.bottom - _imageOffset.dy) / _displaySize.height,
    );
  }

  /// Handle touch on corners
  int? _getCornerAtPosition(Offset localPosition) {
    const double touchRadius = 30.0;
    
    final corners = [
      _cropRect.topLeft,
      _cropRect.topRight,
      _cropRect.bottomRight,
      _cropRect.bottomLeft,
    ];
    
    for (int i = 0; i < corners.length; i++) {
      if ((localPosition - corners[i]).distance < touchRadius) {
        return i;
      }
    }
    return null;
  }

  /// Check if touch is inside crop rect (for dragging)
  bool _isInsideCropRect(Offset localPosition) {
    return _cropRect.contains(localPosition);
  }

  void _handlePanStart(DragStartDetails details) {
    final localPosition = details.localPosition;
    
    // Check if touching a corner
    _activeCorner = _getCornerAtPosition(localPosition);
    
    if (_activeCorner != null) {
      _dragStart = localPosition;
      _dragStartRect = _cropRect;
    } else if (_isInsideCropRect(localPosition)) {
      // Drag entire rect
      _activeCorner = -1; // Special value for move
      _dragStart = localPosition;
      _dragStartRect = _cropRect;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _dragStartRect == null) return;
    
    final delta = details.localPosition - _dragStart!;
    final minSize = 50.0;
    
    setState(() {
      if (_activeCorner == -1) {
        // Move entire rect
        Rect newRect = _dragStartRect!.shift(delta);
        
        // Clamp to image bounds
        final double left = newRect.left.clamp(_imageOffset.dx, _imageOffset.dx + _displaySize.width - newRect.width);
        final double top = newRect.top.clamp(_imageOffset.dy, _imageOffset.dy + _displaySize.height - newRect.height);
        
        _cropRect = Rect.fromLTWH(left, top, newRect.width, newRect.height);
      } else {
        // Resize from corner
        Rect newRect = _dragStartRect!;
        
        switch (_activeCorner) {
          case 0: // Top-left
            newRect = Rect.fromLTRB(
              (_dragStartRect!.left + delta.dx).clamp(_imageOffset.dx, _dragStartRect!.right - minSize),
              (_dragStartRect!.top + delta.dy).clamp(_imageOffset.dy, _dragStartRect!.bottom - minSize),
              _dragStartRect!.right,
              _dragStartRect!.bottom,
            );
            break;
          case 1: // Top-right
            newRect = Rect.fromLTRB(
              _dragStartRect!.left,
              (_dragStartRect!.top + delta.dy).clamp(_imageOffset.dy, _dragStartRect!.bottom - minSize),
              (_dragStartRect!.right + delta.dx).clamp(_dragStartRect!.left + minSize, _imageOffset.dx + _displaySize.width),
              _dragStartRect!.bottom,
            );
            break;
          case 2: // Bottom-right
            newRect = Rect.fromLTRB(
              _dragStartRect!.left,
              _dragStartRect!.top,
              (_dragStartRect!.right + delta.dx).clamp(_dragStartRect!.left + minSize, _imageOffset.dx + _displaySize.width),
              (_dragStartRect!.bottom + delta.dy).clamp(_dragStartRect!.top + minSize, _imageOffset.dy + _displaySize.height),
            );
            break;
          case 3: // Bottom-left
            newRect = Rect.fromLTRB(
              (_dragStartRect!.left + delta.dx).clamp(_imageOffset.dx, _dragStartRect!.right - minSize),
              _dragStartRect!.top,
              _dragStartRect!.right,
              (_dragStartRect!.bottom + delta.dy).clamp(_dragStartRect!.top + minSize, _imageOffset.dy + _displaySize.height),
            );
            break;
        }
        
        _cropRect = newRect;
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _activeCorner = null;
    _dragStart = null;
    _dragStartRect = null;
  }

  Future<void> _performCrop() async {
    if (_isCropping) return;
    
    setState(() => _isCropping = true);
    
    try {
      final normalizedRect = _toNormalizedRect(_cropRect);
      
      final result = await ImageCropService.cropImage(
        imagePath: widget.imagePath,
        cropRect: normalizedRect,
      );
      
      if (mounted) {
        Navigator.pop(context, result.filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обрезки: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Обрезка'),
        actions: [
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _cropRect != Rect.zero ? _performCrop : null,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Готово', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Image with crop overlay
          LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_displaySize == Size.zero && constraints.maxWidth > 0) {
                  setState(() {
                    _displaySize = Size(constraints.maxWidth, constraints.maxHeight);
                    _imageOffset = Offset.zero;
                  });
                  _initCropRect();
                }
              });
              
              return GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Stack(
                      children: [
                        // Image
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                        
                        // Crop overlay
                        if (_cropRect != Rect.zero)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CropOverlayPainter(
                                cropRect: _cropRect,
                                corner: _activeCorner,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Instructions
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Тяните углы или двигайте область',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter for crop overlay with dimmed areas and crop rect
class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final int? corner;

  CropOverlayPainter({
    required this.cropRect,
    this.corner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dimmed overlay (everything except crop area)
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw dimmed areas (outside crop rect)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cropRect, Radius.zero))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, overlayPaint);

    // Crop rect border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(cropRect, borderPaint);

    // Grid lines (rule of thirds)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Vertical lines
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.bottom),
      gridPaint,
    );
    
    // Horizontal lines
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height * 2 / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height * 2 / 3),
      gridPaint,
    );

    // Corner handles
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final cornerRadius = 12.0;
    final cornerLength = 24.0;
    final cornerWidth = 4.0;
    
    final corners = [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomRight,
      cropRect.bottomLeft,
    ];
    
    for (int i = 0; i < corners.length; i++) {
      final isHighlighted = corner == i;
      final paint = Paint()
        ..color = isHighlighted ? Colors.blue : Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(corners[i], isHighlighted ? cornerRadius + 4 : cornerRadius, paint);
      
      // Draw corner brackets
      final bracketPaint = Paint()
        ..color = isHighlighted ? Colors.blue : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = cornerWidth
        ..strokeCap = StrokeCap.round;
      
      switch (i) {
        case 0: // Top-left
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx + cornerLength, corners[i].dy),
            bracketPaint,
          );
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx, corners[i].dy + cornerLength),
            bracketPaint,
          );
          break;
        case 1: // Top-right
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx - cornerLength, corners[i].dy),
            bracketPaint,
          );
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx, corners[i].dy + cornerLength),
            bracketPaint,
          );
          break;
        case 2: // Bottom-right
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx - cornerLength, corners[i].dy),
            bracketPaint,
          );
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx, corners[i].dy - cornerLength),
            bracketPaint,
          );
          break;
        case 3: // Bottom-left
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx + cornerLength, corners[i].dy),
            bracketPaint,
          );
          canvas.drawLine(
            Offset(corners[i].dx, corners[i].dy),
            Offset(corners[i].dx, corners[i].dy - cornerLength),
            bracketPaint,
          );
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return cropRect != oldDelegate.cropRect || corner != oldDelegate.corner;
  }
}
