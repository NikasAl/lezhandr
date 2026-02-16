import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/problems_provider.dart';
import '../../widgets/shared/persona_selector.dart';

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
          // Показать успешную загрузку
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Фото успешно загружено'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Предложить OCR для условия или решения
          if (widget.category == 'condition' || widget.category == 'solution') {
            await _offerOcrAfterUpload();
          }

          // Обновить данные задачи если это условие
          if (widget.category == 'condition') {
            ref.invalidate(problemProvider(widget.entityId));
          }

          if (mounted) {
            Navigator.pop(context, _capturedImagePath);
          }
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

  /// Предложить OCR после загрузки фото (как в CLI mv_screens.py:469)
  Future<void> _offerOcrAfterUpload() async {
    if (!mounted) return;

    final ocrTitle = widget.category == 'condition'
        ? 'Распознать условие задачи?'
        : 'Распознать текст решения?';

    final doOcr = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.purple),
            const SizedBox(width: 8),
            const Expanded(child: Text('AI Распознавание')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ocrTitle),
            const SizedBox(height: 8),
            const Text(
              'Выберите AI-персону для распознавания текста с фотографии:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.document_scanner),
            label: const Text('Распознать'),
          ),
        ],
      ),
    );

    if (doOcr != true || !mounted) return;

    // Показать выбор персоны
    final persona = await showPersonaSheet(
      context,
      defaultPersona: PersonaId.petrovich,
    );

    if (persona == null || !mounted) return;

    // Запустить OCR
    bool ocrSuccess = false;
    if (widget.category == 'condition') {
      final result = await ref.read(ocrNotifierProvider.notifier).processProblem(
        problemId: widget.entityId,
        persona: persona,
      );
      ocrSuccess = result.success;
    } else {
      final result = await ref.read(ocrNotifierProvider.notifier).processSolution(
        solutionId: widget.entityId,
        persona: persona,
      );
      ocrSuccess = result.success;
    }

    if (mounted) {
      if (ocrSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Текст успешно распознан!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final ocrState = ref.read(ocrNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка OCR: ${ocrState.error ?? "Неизвестная ошибка"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
