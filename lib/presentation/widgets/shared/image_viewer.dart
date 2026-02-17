import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ocr_provider.dart';

/// Full screen image viewer with zoom support
/// Uses authorized image loading via provider
class ImageViewerScreen extends ConsumerWidget {
  final String category;
  final int entityId;
  final String? title;

  const ImageViewerScreen({
    super.key,
    required this.category,
    required this.entityId,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(imageProvider((category: category, entityId: entityId)));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Фото'),
      ),
      body: imageAsync.when(
        data: (bytes) {
          if (bytes == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Изображение не найдено',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка отображения',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки: $error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(imageProvider((category: category, entityId: entityId))),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail image with tap to view fullscreen
/// Uses authorized image loading via provider
class ImageThumbnail extends ConsumerWidget {
  final String category;
  final int entityId;
  final String? title;
  final double height;
  final double? width;

  const ImageThumbnail({
    super.key,
    required this.category,
    required this.entityId,
    this.title,
    this.height = 200,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(imageProvider((category: category, entityId: entityId)));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              category: category,
              entityId: entityId,
              title: title,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          width: width,
          constraints: width == null ? null : BoxConstraints(maxWidth: width!),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageAsync.when(
                data: (bytes) {
                  if (bytes == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Нет фото',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 32,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ошибка',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 32,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ошибка',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Zoom indicator
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience widget for condition images
class ConditionImageThumbnail extends ConsumerWidget {
  final int problemId;
  final String? title;
  final double height;
  final double? width;

  const ConditionImageThumbnail({
    super.key,
    required this.problemId,
    this.title,
    this.height = 200,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ImageThumbnail(
      category: 'condition',
      entityId: problemId,
      title: title,
      height: height,
      width: width,
    );
  }
}

/// Convenience widget for solution images
class SolutionImageThumbnail extends ConsumerWidget {
  final int solutionId;
  final String? title;
  final double height;
  final double? width;

  const SolutionImageThumbnail({
    super.key,
    required this.solutionId,
    this.title,
    this.height = 200,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ImageThumbnail(
      category: 'solution',
      entityId: solutionId,
      title: title,
      height: height,
      width: width,
    );
  }
}
