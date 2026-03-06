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
import '../../../widgets/shared/math_zoom_dialog.dart';

/// Condition card with image/text toggle and OCR support
class ConditionCard extends ConsumerStatefulWidget {
  final ProblemModel problem;
  final bool isOwner;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onOcr;

  const ConditionCard({
    super.key,
    required this.problem,
    required this.isOwner,
    this.canEdit = true,
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
                // Owner-only buttons (OCR only if can edit)
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
                            onPressed: widget.canEdit ? widget.onOcr : null,
                            tooltip: widget.canEdit 
                                ? 'Распознать текст (OCR)' 
                                : 'Недоступно для задач на модерации',
                          ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: widget.canEdit ? widget.onEdit : null,
                    tooltip: widget.canEdit 
                        ? 'Редактировать текст' 
                        : 'Недоступно для прошедших модерацию',
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
        onFormulaTap: (latex) {
          MathZoomDialog.show(context, latex: latex);
        },
      );
    }

    if (widget.problem.hasImage) {
      // Use ConditionImageThumbnail from image_viewer.dart which properly
      // loads images via imageProvider with authorization
      return ConditionImageThumbnail(
        problemId: widget.problem.id,
        title: 'Условие: ${widget.problem.reference}',
        height: 250,
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    String message;
    if (!widget.isOwner) {
      message = 'Условие не добавлено';
    } else if (!widget.canEdit) {
      message = widget.problem.isApproved 
          ? 'Задача прошла модерацию' 
          : 'Задача отклонена модератором';
    } else {
      message = 'Нажмите ⋮ для добавления условия';
    }
    
    return Center(
      child: Column(
        children: [
          Icon(
            widget.canEdit 
                ? Icons.add_photo_alternate_outlined 
                : (widget.problem.isRejected ? Icons.block : Icons.verified),
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
