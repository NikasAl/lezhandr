import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/solutions_provider.dart';
import '../../providers/artifacts_provider.dart';
import '../../widgets/shared/image_viewer.dart';

/// Solution photo card with upload capability
class SolutionPhotoCard extends StatelessWidget {
  final int solutionId;
  final bool hasImage;
  final bool isOwner;
  final VoidCallback onImageUpdated;

  const SolutionPhotoCard({
    super.key,
    required this.solutionId,
    required this.hasImage,
    required this.isOwner,
    required this.onImageUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Фото решения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (isOwner)
                  TextButton.icon(
                    onPressed: () async {
                      await context.push(
                          '/camera?category=solution&entityId=$solutionId');
                      onImageUpdated();
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(hasImage ? 'Обновить' : 'Добавить'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasImage)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        category: 'solution',
                        entityId: solutionId,
                        title: 'Фото решения',
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SolutionImageThumbnail(
                    solutionId: solutionId,
                    title: 'Фото решения',
                    height: 250,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwner 
                          ? 'Нажмите "Добавить" чтобы загрузить фото'
                          : 'Фото не добавлено',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
