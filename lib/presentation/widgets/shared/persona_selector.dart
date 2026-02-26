import 'package:flutter/material.dart';
import '../../../data/models/artifacts.dart';

/// Persona selection widget
class PersonaSelector extends StatelessWidget {
  final PersonaId selectedPersona;
  final Function(PersonaId) onPersonaSelected;
  final bool showCost;
  final int? freeUsesLeft;
  final VoidCallback? onDisabledPersonaTap;

  const PersonaSelector({
    super.key,
    required this.selectedPersona,
    required this.onPersonaSelected,
    this.showCost = true,
    this.freeUsesLeft,
    this.onDisabledPersonaTap,
  });

  /// Check if a persona is disabled (only basis can be disabled due to free uses limit)
  bool _isPersonaDisabled(PersonaId persona) {
    if (persona == PersonaId.basis) {
      return freeUsesLeft != null && freeUsesLeft! <= 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤔 Кого спросим?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: PersonaId.values.map((persona) {
            final isSelected = persona == selectedPersona;
            final isDisabled = _isPersonaDisabled(persona);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: persona != PersonaId.values.last ? 8 : 0,
                ),
                child: _PersonaCard(
                  persona: persona,
                  isSelected: isSelected,
                  isDisabled: isDisabled,
                  onTap: () => onPersonaSelected(persona),
                  onDisabledTap: onDisabledPersonaTap,
                  showCost: showCost,
                  freeUsesLeft: freeUsesLeft,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final PersonaId persona;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  final VoidCallback? onDisabledTap;
  final bool showCost;
  final int? freeUsesLeft;

  const _PersonaCard({
    required this.persona,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    this.onDisabledTap,
    required this.showCost,
    this.freeUsesLeft,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPersonaColor(persona);
    final theme = Theme.of(context);

    // Disabled state styling
    final backgroundColor = isDisabled
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
        : isSelected
            ? color.withOpacity(0.2)
            : theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,  // Always allow selection for visual feedback
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                _getPersonaEmoji(persona),
                style: TextStyle(
                  fontSize: 28,
                  color: isDisabled ? theme.colorScheme.onSurface.withOpacity(0.4) : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getPersonaShortName(persona),
                style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected && !isDisabled ? FontWeight.bold : FontWeight.normal,
                      color: isDisabled
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : isSelected
                              ? color
                              : null,
                    ),
                textAlign: TextAlign.center,
              ),
              if (showCost && !isDisabled) ...[
                const SizedBox(height: 2),
                Text(
                  persona.cost > 0 ? '${persona.cost.toStringAsFixed(0)} ₽' : 'Free',
                  style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? color : null,
                      ),
                ),
              ],
              // Show "sleeping" message for disabled basis
              if (isDisabled && persona == PersonaId.basis) ...[
                const SizedBox(height: 2),
                Text(
                  '💤 Сплю...',
                  style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.error 
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPersonaColor(PersonaId persona) {
    switch (persona) {
      case PersonaId.basis:
        return Colors.green;
      case PersonaId.petrovich:
        return Colors.orange;
      case PersonaId.legendre:
        return Colors.blue;
    }
  }

  String _getPersonaEmoji(PersonaId persona) {
    switch (persona) {
      case PersonaId.basis:
        return '🐱';
      case PersonaId.petrovich:
        return '🧹';
      case PersonaId.legendre:
        return '🧐';
    }
  }

  String _getPersonaShortName(PersonaId persona) {
    switch (persona) {
      case PersonaId.basis:
        return 'Базис';
      case PersonaId.petrovich:
        return 'Петрович';
      case PersonaId.legendre:
        return 'Лежандр';
    }
  }
}

/// Show persona selection dialog
Future<PersonaId?> showPersonaSelectorDialog(
  BuildContext context, {
  PersonaId defaultPersona = PersonaId.petrovich,
  String title = 'Выберите AI',
  int? freeUsesLeft,
}) async {
  PersonaId selected = defaultPersona;

  return await showDialog<PersonaId>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isBasisDisabled = freeUsesLeft != null && freeUsesLeft <= 0;
        final isSelectionDisabled = selected == PersonaId.basis && isBasisDisabled;
        
        return AlertDialog(
          title: Text(title),
          content: PersonaSelector(
            selectedPersona: selected,
            freeUsesLeft: freeUsesLeft,
            onPersonaSelected: (persona) {
              setState(() => selected = persona);
            },
            onDisabledPersonaTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🐱 Кот Базис устал сегодня. Выберите другого персонажа!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: isSelectionDisabled
                  ? null  // Disable button visually when disabled persona selected
                  : () => Navigator.pop(context, selected),
              child: Text(isSelectionDisabled ? 'Выберите другого' : 'Выбрать'),
            ),
          ],
        );
      },
    ),
  );
}

/// Simple persona selection bottom sheet
Future<PersonaId?> showPersonaSheet(
  BuildContext context, {
  PersonaId defaultPersona = PersonaId.petrovich,
  int? freeUsesLeft,
}) async {
  PersonaId selected = defaultPersona;

  return await showModalBottomSheet<PersonaId>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isBasisDisabled = freeUsesLeft != null && freeUsesLeft <= 0;
        final isSelectionDisabled = selected == PersonaId.basis && isBasisDisabled;
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonaSelector(
                selectedPersona: selected,
                freeUsesLeft: freeUsesLeft,
                onPersonaSelected: (persona) {
                  setState(() => selected = persona);
                },
                onDisabledPersonaTap: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🐱 Кот Базис устал сегодня. Выберите другого персонажа!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Show message when disabled persona is selected
              if (isSelectionDisabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '🐱 Кот Базис устал сегодня. Выберите другого персонажа!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSelectionDisabled
                      ? null  // Disable button visually when disabled persona selected
                      : () => Navigator.pop(context, selected),
                  child: Text(isSelectionDisabled ? 'Недоступно' : 'Запросить'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
