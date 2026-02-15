import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/ocr_provider.dart';

/// Camera screen for capturing images
class CameraScreen extends ConsumerStatefulWidget {
  final String category;
  final int entityId;

  const CameraScreen({
    super.key,
    required this.category,
    required this.entityId,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _capturedImagePath;
  bool _isUploading = false;

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (image != null) {
      setState(() => _capturedImagePath = image.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (image != null) {
      setState(() => _capturedImagePath = image.path);
    }
  }

  Future<void> _uploadImage() async {
    if (_capturedImagePath == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await ref.read(uploadNotifierProvider.notifier).uploadImage(
        category: widget.category,
        entityId: widget.entityId,
        filePath: _capturedImagePath!,
      );

      if (mounted) {
        if (result.success) {
          Navigator.pop(context, _capturedImagePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String get _categoryTitle {
    switch (widget.category) {
      case 'condition':
        return 'Условие задачи';
      case 'solution':
        return 'Решение';
      case 'epiphany':
        return 'Схема озарения';
      case 'question':
        return 'Контекст вопроса';
      case 'hint':
        return 'Контекст подсказки';
      default:
        return 'Изображение';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _categoryTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_capturedImagePath != null) {
      return _buildPreview();
    }
    return _buildCaptureOptions();
  }

  Widget _buildCaptureOptions() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[900],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Выберите источник изображения',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              top: BorderSide(color: Colors.grey[800]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: _pickFromGallery,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Камера',
                  onTap: _takePicture,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isPrimary ? Theme.of(context).primaryColor : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            child: Image.file(
              File(_capturedImagePath!),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              top: BorderSide(color: Colors.grey[800]!),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _categoryTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _capturedImagePath = null);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Переснять'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isUploading ? null : _uploadImage,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isUploading ? 'Загрузка...' : 'Отправить'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
