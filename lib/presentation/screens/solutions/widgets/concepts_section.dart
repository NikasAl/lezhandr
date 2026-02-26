import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/concepts_repository.dart';
import '../../../../data/models/artifacts.dart';
import '../../../providers/solutions_provider.dart';
import '../../../providers/ocr_provider.dart';
import '../../../widgets/shared/persona_selector.dart';
import '../../../widgets/shared/markdown_with_math.dart';
import '../../../widgets/shared/thinking_indicator.dart';

/// Solution concepts section widget
class SolutionConceptsSection extends ConsumerWidget {
  final int solutionId;
  final bool isLoading;
  final PersonaId? currentPersona;
  final VoidCallback onAnalyze;

  const SolutionConceptsSection({
    super.key,
    required this.solutionId,
    required this.isLoading,
    this.currentPersona,
    required this.onAnalyze,
  });

  void _showConceptDetail(BuildContext context, SolutionConceptModel concept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        concept.concept?.name ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (concept.usageContext != null && concept.usageContext!.isNotEmpty) ...[
                        Text(
                          'Контекст использования',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MarkdownWithMath(
                          text: concept.usageContext!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (concept.concept?.description != null && concept.concept!.description!.isNotEmpty) ...[
                        Text(
                          'Описание навыка',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MarkdownWithMath(
                          text: concept.concept!.description!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (concept.concept?.utilityDescription != null && concept.concept!.utilityDescription!.isNotEmpty) ...[
                        Text(
                          'Практическое применение',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MarkdownWithMath(
                          text: concept.concept!.utilityDescription!,
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conceptsAsync = ref.watch(solutionConceptsProvider(solutionId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Навыки',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (!isLoading)
                  TextButton.icon(
                    onPressed: onAnalyze,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Анализ'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Show thinking indicator when loading
            if (isLoading)
              ThinkingIndicator(persona: currentPersona ?? PersonaId.legendre)
            else
              conceptsAsync.when(
                data: (concepts) {
                  if (concepts.isEmpty) {
                    return Text(
                      'Навыки не определены. Нажмите "Анализ" для автоматического определения.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: concepts.map((concept) {
                      return GestureDetector(
                        onTap: () => _showConceptDetail(context, concept),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  concept.concept?.name ?? 'Unknown',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Text(
                  'Ошибка загрузки навыков: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
