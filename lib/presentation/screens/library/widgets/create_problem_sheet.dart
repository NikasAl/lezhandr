import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/problem.dart';
import '../../../../data/repositories/problems_repository.dart';
import '../../../../presentation/providers/problems_provider.dart';
import '../../../providers/providers.dart';
import '../../../providers/ocr_provider.dart';
import '../../camera/image_cropper_screen.dart';
import 'tags_selector.dart';

/// Result of problem creation
class CreateProblemResult {
  final ProblemModel problem;
  final String? photoPath; // Path to uploaded photo (if any)

  CreateProblemResult({required this.problem, this.photoPath});
}

/// Create problem bottom sheet
class CreateProblemSheet extends ConsumerStatefulWidget {
  final List<SourceModel> sources;
  final String? selectedSource;
  final WidgetRef ref;

  const CreateProblemSheet({
    super.key,
    required this.sources,
    required this.selectedSource,
    required this.ref,
  });

  @override
  ConsumerState<CreateProblemSheet> createState() => _CreateProblemSheetState();
}

class _CreateProblemSheetState extends ConsumerState<CreateProblemSheet> {
  late final TextEditingController _refController;
  late final TextEditingController _conditionController;
  late List<SourceModel> _sources;
  String? _selectedSourceName;
  List<String> _selectedTags = [];
  bool _isLoading = false;
  
  // Photo state
  String? _selectedPhotoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController();
    _conditionController = TextEditingController();
    _sources = List.from(widget.sources);
    _selectedSourceName = widget.selectedSource;
  }

  @override
  void dispose() {
    _refController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (image != null) {
      await _processImage(image.path);
    }
  }

  /// Take picture with camera
  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (image != null) {
      await _processImage(image.path);
    }
  }

  /// Process captured image - open cropper
  Future<void> _processImage(String imagePath) async {
    if (!mounted) return;
    
    final croppedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropperScreen(
          imagePath: imagePath,
          title: 'Фото условия',
        ),
      ),
    );
    
    if (croppedPath != null && mounted) {
      setState(() => _selectedPhotoPath = croppedPath);
    } else if (mounted) {
      // User cancelled cropping - still use the original image
      setState(() => _selectedPhotoPath = imagePath);
    }
  }

  /// Remove selected photo
  void _removePhoto() {
    setState(() => _selectedPhotoPath = null);
  }

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить фото'),
        content: const Text('Выберите источник изображения для условия задачи'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'gallery'),
            child: const Text('Галерея'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Камера'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result == 'gallery') {
      await _pickFromGallery();
    } else if (result == 'camera') {
      await _takePicture();
    }
  }

  Future<void> _createProblem() async {
    if (_refController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер/название задачи')),
      );
      return;
    }
    if (_selectedSourceName == null || _selectedSourceName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите или создайте источник')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = widget.ref.read(problemsRepositoryProvider);
      final problem = await repo.createProblem(
        ProblemCreate(
          reference: _refController.text,
          sourceName: _selectedSourceName!,
          tags: _selectedTags,
          conditionText: _conditionController.text.isEmpty
              ? null
              : _conditionController.text,
        ),
      );

      // If photo was selected, upload it
      String? uploadedPhotoPath;
      if (_selectedPhotoPath != null && problem.id != null) {
        try {
          final uploadResult = await widget.ref.read(uploadNotifierProvider.notifier).uploadImage(
            category: 'condition',
            entityId: problem.id!,
            filePath: _selectedPhotoPath!,
          );
          if (uploadResult.success) {
            uploadedPhotoPath = _selectedPhotoPath;
          }
        } catch (e) {
          // Photo upload failed, but problem was created
          debugPrint('Photo upload failed: $e');
        }
      }

      if (mounted) {
        // Return the created problem with photo info
        Navigator.of(context).pop(CreateProblemResult(
          problem: problem,
          photoPath: uploadedPhotoPath,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showNewSourceSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const NewSourceSheet(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        final existingNames = _sources.map((s) => s.name).toSet();
        if (!existingNames.contains(result)) {
          // Add as pending source (will be created on server with pending status)
          _sources.add(SourceModel(
            name: result,
            slug: result.toLowerCase().replaceAll(' ', '-'),
            moderationStatus: 'pending',
          ));
          _sources.sort((a, b) => a.name.compareTo(b.name));
        }
        _selectedSourceName = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_task, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Новая задача',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Photo section (moved to top for better UX)
            Text(
              'Фото условия (опционально)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            
            if (_selectedPhotoPath != null) ...[
              // Photo preview with zoom support
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(_selectedPhotoPath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Заменить фото'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removePhoto,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить фото',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Photo selection buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Галерея'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Камера'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Source selection
            Text(
              'Источник',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSourceName,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Выберите или введите новый',
              ),
              items: _sources.map((source) {
                final isPending = source.isPending;
                return DropdownMenuItem(
                  value: source.name,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          source.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'на модерации',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSourceName = value);
              },
            ),
            // Custom source input hint
            TextButton.icon(
              onPressed: _showNewSourceSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Новый источник'),
            ),
            const SizedBox(height: 16),

            // Reference (number/name)
            Text(
              'Номер/Название',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Например: 1.23 или Задача №5',
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            Text(
              'Теги',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TagsSelector(
              selectedTags: _selectedTags,
              onTagsChanged: (tags) {
                setState(() => _selectedTags = tags);
              },
            ),
            const SizedBox(height: 16),

            // Condition text
            Text(
              'Условие (опционально)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _conditionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Текст условия задачи...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _createProblem,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Создание...' : 'Создать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// New source bottom sheet
class NewSourceSheet extends StatefulWidget {
  const NewSourceSheet({super.key});

  @override
  State<NewSourceSheet> createState() => _NewSourceSheetState();
}

class _NewSourceSheetState extends State<NewSourceSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_outlined, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Новый источник',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Source name input
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Название источника',
                hintText: 'Например: Книга "Алгебра 10 класс"',
              ),
              autofocus: true,
              onSubmitted: (value) {
                final name = value.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      final name = _controller.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.of(context).pop(name);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
