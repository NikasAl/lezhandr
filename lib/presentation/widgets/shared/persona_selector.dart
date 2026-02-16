import 'package:flutter/material.dart';
import '../../../data/models/artifacts.dart';

/// Persona selection widget
class PersonaSelector extends StatelessWidget {
  final PersonaId selectedPersona;
  final Function(PersonaId) onPersonaSelected;
  final bool showCost;

  const PersonaSelector({
    super.key,
    required this.selectedPersona,
    required this.onPersonaSelected,
    this.showCost = true,
  });

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
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: persona != PersonaId.values.last ? 8 : 0,
                ),
                child: _PersonaCard(
                  persona: persona,
                  isSelected: isSelected,
                  onTap: () => onPersonaSelected(persona),
                  showCost: showCost,
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
  final VoidCallback onTap;
  final bool showCost;

  const _PersonaCard({
    required this.persona,
    required this.isSelected,
    required this.onTap,
    required this.showCost,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPersonaColor(persona);

    return Material(
      color: isSelected
          ? color.withOpacity(0.2)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                _getPersonaEmoji(persona),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                _getPersonaShortName(persona),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : null,
                    ),
                textAlign: TextAlign.center,
              ),
              if (showCost) ...[
                const SizedBox(height: 2),
                Text(
                  persona.cost > 0 ? '${persona.cost.toStringAsFixed(0)} ₽' : 'Free',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected ? color : null,
                      ),
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
}) async {
  PersonaId selected = defaultPersona;

  return await showDialog<PersonaId>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: PersonaSelector(
          selectedPersona: selected,
          onPersonaSelected: (persona) {
            setState(() => selected = persona);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Выбрать'),
          ),
        ],
      ),
    ),
  );
}

/// Simple persona selection bottom sheet
Future<PersonaId?> showPersonaSheet(
  BuildContext context, {
  PersonaId defaultPersona = PersonaId.petrovich,
}) async {
  PersonaId selected = defaultPersona;

  return await showModalBottomSheet<PersonaId>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersonaSelector(
              selectedPersona: selected,
              onPersonaSelected: (persona) {
                setState(() => selected = persona);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Запросить'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
