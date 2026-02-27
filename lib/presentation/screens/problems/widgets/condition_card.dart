import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/problem.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/problems_provider.dart';
import '../../../providers/ocr_provider.dart';
import '../../../widgets/shared/markdown_with_math.dart';
import '../../../widgets/shared/image_viewer.dart';
import '../../../widgets/shared/thinking_indicator.dart';
import '../../../widgets/shared/persona_selector.dart';

/// Condition card with image/text toggle and OCR support
class ConditionCard extends ConsumerStatefulWidget {
  final ProblemModel problem;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onOcr;

  const ConditionCard({
    super.key,
    required this.problem,
    required this.isOwner,
    required this.onEdit,
    required this.onOcr,
  });

  @override
  ConsumerState<ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends ConsumerState<ConditionCard> {
  bool _showConditionImage = false;

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrNotifierProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Условие',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // Owner-only buttons
                if (widget.isOwner) ...[
                  if (widget.problem.hasImage)
                    ocrState.isLoading
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ThinkingIndicator(
                              persona: ocrState.currentPersona ?? PersonaId.petrovich,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            onPressed: widget.onOcr,
                            tooltip: 'Распознать текст (OCR)',
                          ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: widget.onEdit,
                      tooltip: 'Редактировать текст',
                    ),
                ],
                if (widget.problem.hasImage && widget.problem.hasText)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showConditionImage = !_showConditionImage);
                    },
                    icon: Icon(
                      _showConditionImage ? Icons.text_fields : Icons.image_outlined,
                      size: 18,
                    ),
                    label: Text(_showConditionImage ? 'Текст' : 'Фото'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content: text, image, or placeholder
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.problem.hasText && !_showConditionImage) {
      return MarkdownWithMath(
        text: widget.problem.conditionText!,
        textStyle: Theme.of(context).textTheme.bodyLarge,
      );
    } 
    
    if (widget.problem.hasImage) {
      return ConditionImageThumbnail(
        problemId: widget.problem.id,
        title: 'Условие: ${widget.problem.reference}',
        height: 250,
      );
    }
    
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOwner 
                ? 'Нажмите ⋮ для добавления условия'
                : 'Условие не добавлено',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail for condition image with tap to view
class ConditionImageThumbnail extends StatelessWidget {
  final int problemId;
  final String title;
  final double height;

  const ConditionImageThumbnail({
    super.key,
    required this.problemId,
    required this.title,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              category: 'condition',
              entityId: problemId,
              title: title,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          '/api/problems/$problemId/image',
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
