import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/concepts_repository.dart';
import '../../../providers/solutions_provider.dart';
import '../../../widgets/shared/thinking_indicator.dart';
import '../../../widgets/shared/persona_selector.dart';
import '../../../widgets/shared/markdown_with_math.dart';

/// Skills section for solution detail screen
/// Uses inline expansion design consistent with problem concepts
class SolutionSkillsSection extends ConsumerStatefulWidget {
  final int solutionId;
  final bool isLoading;
  final PersonaId? currentPersona;
  final VoidCallback? onAnalyze;
  final bool showAnalyzeButton;

  const SolutionSkillsSection({
    super.key,
    required this.solutionId,
    this.isLoading = false,
    this.currentPersona,
    this.onAnalyze,
    this.showAnalyzeButton = true,
  });

  @override
  ConsumerState<SolutionSkillsSection> createState() => _SolutionSkillsSectionState();
}

class _SolutionSkillsSectionState extends ConsumerState<SolutionSkillsSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final conceptsAsync = ref.watch(solutionConceptsProvider(widget.solutionId));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            
            if (widget.isLoading)
              ThinkingIndicator(persona: widget.currentPersona ?? PersonaId.legendre)
            else
              conceptsAsync.when(
                data: (concepts) => concepts.isEmpty
                    ? _buildEmptyState()
                    : _buildConceptsList(concepts),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
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
        if (!widget.isLoading && widget.showAnalyzeButton)
          TextButton.icon(
            onPressed: widget.onAnalyze,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Анализ'),
          ),
      ],
    );
  }

  Widget _buildConceptsList(List<SolutionConceptModel> concepts) {
    return Column(
      children: concepts.asMap().entries.map((entry) {
        final index = entry.key;
        final concept = entry.value;
        final isExpanded = _expandedIndex == index;
        final color = _getSkillColor(index, concepts.length);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkillChip(
              name: concept.concept?.name ?? 'Unknown',
              color: color,
              isExpanded: isExpanded,
              onTap: () => setState(() {
                _expandedIndex = isExpanded ? null : index;
              }),
            ),
            
            if (isExpanded) ...[
              const SizedBox(height: 8),
              _SkillDetailsCard(
                usageContext: concept.usageContext,
                conceptDescription: concept.concept?.description,
                utilityDescription: concept.concept?.utilityDescription,
              ),
            ],
            
            if (index < concepts.length - 1)
              const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Навыки не определены',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSkillColor(int index, int total) {
    // Use different colors for variety
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}

/// Clickable skill chip
class _SkillChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SkillChip({
    required this.name,
    required this.color,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? color : color.withOpacity(0.3),
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.school_outlined, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Details card for expanded skill
class _SkillDetailsCard extends StatelessWidget {
  final String? usageContext;
  final String? conceptDescription;
  final String? utilityDescription;

  const _SkillDetailsCard({
    this.usageContext,
    this.conceptDescription,
    this.utilityDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usageContext != null && usageContext!.isNotEmpty) ...[
          _SectionRow(
            icon: Icons.forum_outlined,
            title: 'Контекст использования',
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          MarkdownWithMath(
            text: usageContext!,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (conceptDescription != null && conceptDescription!.isNotEmpty) ...[
          _SectionRow(
            icon: Icons.info_outline,
            title: 'Описание навыка',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          MarkdownWithMath(
            text: conceptDescription!,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (utilityDescription != null && utilityDescription!.isNotEmpty) ...[
          _SectionRow(
            icon: Icons.tips_and_updates_outlined,
            title: 'Практическое применение',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          MarkdownWithMath(
            text: utilityDescription!,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// Section row with icon and title
class _SectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionRow({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
