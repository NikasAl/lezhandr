import 'package:flutter/material.dart';
import '../../../core/motivation/motivation_models.dart';

/// Card widget for displaying motivation text
class MotivationCard extends StatelessWidget {
  final MotivationText motivation;
  final VoidCallback? onDismiss;
  final bool showAuthor;
  final bool animate;

  const MotivationCard({
    super.key,
    required this.motivation,
    this.onDismiss,
    this.showAuthor = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(motivation.category),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getCategoryTitle(motivation.category),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Text
          Text(
            motivation.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
          ),

          // Author
          if (showAuthor && motivation.author != null) ...[
            const SizedBox(height: 12),
            Text(
              '— ${motivation.author}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],

          // Dismiss button
          if (onDismiss != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDismiss,
                child: const Text('Понятно'),
              ),
            ),
          ],
        ],
      ),
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: widget,
      );
    }

    return widget;
  }

  IconData _getCategoryIcon(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.thinking:
        return Icons.psychology;
      case MotivationCategory.practical:
        return Icons.build;
      case MotivationCategory.satisfaction:
        return Icons.emoji_events;
      case MotivationCategory.career:
        return Icons.trending_up;
      case MotivationCategory.perseverance:
        return Icons.fitness_center;
      case MotivationCategory.energetic:
        return Icons.bolt;
      case MotivationCategory.quotes:
        return Icons.format_quote;
      case MotivationCategory.session:
        return Icons.timer;
      case MotivationCategory.streak:
        return Icons.local_fire_department;
      case MotivationCategory.achievements:
        return Icons.star;
    }
  }

  String _getCategoryTitle(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.thinking:
        return 'Развитие мышления';
      case MotivationCategory.practical:
        return 'Практическая польза';
      case MotivationCategory.satisfaction:
        return 'Удовлетворение';
      case MotivationCategory.career:
        return 'Будущее и карьера';
      case MotivationCategory.perseverance:
        return 'Преодоление';
      case MotivationCategory.energetic:
        return 'Мотивация';
      case MotivationCategory.quotes:
        return 'Цитата';
      case MotivationCategory.session:
        return 'Совет';
      case MotivationCategory.streak:
        return 'Стрик';
      case MotivationCategory.achievements:
        return 'Достижение';
    }
  }
}

/// Compact banner version of motivation
class MotivationBanner extends StatelessWidget {
  final MotivationText motivation;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const MotivationBanner({
    super.key,
    required this.motivation,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onHorizontalDragEnd: onDismiss != null ? (_) => onDismiss!() : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                motivation.text,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
