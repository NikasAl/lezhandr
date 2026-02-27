import 'package:flutter/material.dart';
import '../../../data/models/problem.dart';
import '../../widgets/shared/thinking_indicator.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/markdown_with_math.dart';

/// Concepts section for problem detail screen
/// Uses inline expansion design for better UX
class ProblemConceptsSection extends StatefulWidget {
  final List<ProblemConceptModel>? concepts;
  final bool isLoading;
  final PersonaId? currentPersona;
  final VoidCallback? onAnalyze;
  final bool showAnalyzeButton;

  const ProblemConceptsSection({
    super.key,
    required this.concepts,
    this.isLoading = false,
    this.currentPersona,
    this.onAnalyze,
    this.showAnalyzeButton = true,
  });

  @override
  State<ProblemConceptsSection> createState() => _ProblemConceptsSectionState();
}

class _ProblemConceptsSectionState extends State<ProblemConceptsSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final hasConcepts = widget.concepts != null && widget.concepts!.isNotEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, hasConcepts),
            const SizedBox(height: 12),
            
            if (widget.isLoading)
              ThinkingIndicator(persona: widget.currentPersona ?? PersonaId.legendre)
            else if (hasConcepts)
              _buildConceptsList()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool hasConcepts) {
    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Концепты',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        if (!widget.isLoading && widget.showAnalyzeButton)
          TextButton.icon(
            onPressed: widget.onAnalyze,
            icon: const Icon(Icons.psychology, size: 18),
            label: Text(hasConcepts ? 'Обновить' : 'Анализ'),
          ),
      ],
    );
  }

  Widget _buildConceptsList() {
    return Column(
      children: widget.concepts!.asMap().entries.map((entry) {
        final index = entry.key;
        final concept = entry.value;
        final isExpanded = _expandedIndex == index;
        final relevance = concept.relevance ?? 0.0;
        final color = _getRelevanceColor(relevance);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConceptChip(
              name: concept.concept?.name ?? 'Unknown',
              relevance: relevance,
              color: color,
              isExpanded: isExpanded,
              onTap: () => setState(() {
                _expandedIndex = isExpanded ? null : index;
              }),
            ),
            
            if (isExpanded) ...[
              const SizedBox(height: 8),
              _ConceptDetailsCard(
                explanation: concept.explanation,
                conceptDescription: concept.concept?.description,
                utilityDescription: concept.concept?.utilityDescription,
              ),
            ],
            
            if (index < widget.concepts!.length - 1)
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
            'Нажмите "Анализ" для определения концептов',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRelevanceColor(double relevance) {
    if (relevance >= 0.8) return Colors.green;
    if (relevance >= 0.5) return Colors.orange;
    return Colors.blue;
  }
}

/// Clickable concept chip with relevance badge
class _ConceptChip extends StatelessWidget {
  final String name;
  final double relevance;
  final Color color;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ConceptChip({
    required this.name,
    required this.relevance,
    required this.color,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final relevancePercent = (relevance * 100).toStringAsFixed(0);
    
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$relevancePercent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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

/// Details card for expanded concept
class _ConceptDetailsCard extends StatelessWidget {
  final String? explanation;
  final String? conceptDescription;
  final String? utilityDescription;

  const _ConceptDetailsCard({
    this.explanation,
    this.conceptDescription,
    this.utilityDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (explanation != null && explanation!.isNotEmpty) ...[
          _SectionRow(
            icon: Icons.forum_outlined,
            title: 'Объяснение',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          MarkdownWithMath(
            text: explanation!,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (conceptDescription != null && conceptDescription!.isNotEmpty) ...[
          _SectionRow(
            icon: Icons.info_outline,
            title: 'Описание концепта',
            color: Theme.of(context).colorScheme.secondary,
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
