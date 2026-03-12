import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/artifacts.dart';
import '../dialogs/top_up_dialog.dart';

/// Persona selection widget
class PersonaSelector extends StatelessWidget {
  final PersonaId selectedPersona;
  final Function(PersonaId) onPersonaSelected;
  final bool showCost;
  final int? freeUsesLeft;
  final double? balance;
  final int? hearts;  // Текущие сердца пользователя
  final VoidCallback? onDisabledPersonaTap;

  const PersonaSelector({
    super.key,
    required this.selectedPersona,
    required this.onPersonaSelected,
    this.showCost = true,
    this.freeUsesLeft,
    this.balance,
    this.hearts,
    this.onDisabledPersonaTap,
  });

  /// Check if a persona is disabled:
  /// - Basis: disabled when free uses exhausted AND no hearts
  /// - Petrovich/Legendre: disabled when insufficient balance AND no hearts
  bool _isPersonaDisabled(PersonaId persona) {
    if (persona == PersonaId.basis) {
      // Basis бесплатен, но имеет дневной лимит
      final freeExhausted = freeUsesLeft != null && freeUsesLeft! <= 0;
      final canUseHearts = hearts != null && hearts! >= 1;
      return freeExhausted && !canUseHearts;
    }
    // Для платных персон - проверяем баланс или сердца
    final hasMoney = balance != null && persona.cost <= balance!;
    final canUseHearts = hearts != null && hearts! >= 1;
    return !hasMoney && !canUseHearts;
  }

  /// Get the reason why persona is disabled
  String _getDisabledReason(PersonaId persona) {
    if (persona == PersonaId.basis) {
      return '💤 Сплю...';
    }
    return 'Недостаточно средств и сердец';
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
        if (hearts != null && hearts! > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.favorite, size: 14, color: Colors.red[400]),
              const SizedBox(width: 4),
              Text(
                'Доступно сердец: $hearts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
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
                  disabledReason: isDisabled ? _getDisabledReason(persona) : null,
                  onTap: () => onPersonaSelected(persona),
                  onDisabledTap: onDisabledPersonaTap,
                  showCost: showCost,
                  balance: balance,
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
  final String? disabledReason;
  final VoidCallback onTap;
  final VoidCallback? onDisabledTap;
  final bool showCost;
  final double? balance;

  const _PersonaCard({
    required this.persona,
    required this.isSelected,
    required this.isDisabled,
    this.disabledReason,
    required this.onTap,
    this.onDisabledTap,
    required this.showCost,
    this.balance,
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
              // Show cost or disabled reason
              if (showCost && !isDisabled) ...[
                const SizedBox(height: 2),
                Text(
                  persona.cost > 0 ? '${persona.cost.toStringAsFixed(0)} ₽' : 'Free',
                  style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? color : null,
                      ),
                ),
              ],
              // Show disabled reason
              if (isDisabled && disabledReason != null) ...[
                const SizedBox(height: 2),
                Text(
                  disabledReason!,
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

bool _isSelectionDisabled(PersonaId persona, int? freeUsesLeft, double? balance, int? hearts) {
  if (persona == PersonaId.basis) {
    final freeExhausted = freeUsesLeft != null && freeUsesLeft <= 0;
    final canUseHearts = hearts != null && hearts >= 1;
    return freeExhausted && !canUseHearts;
  }
  final hasMoney = balance != null && persona.cost <= balance!;
  final canUseHearts = hearts != null && hearts >= 1;
  return !hasMoney && !canUseHearts;
}

/// Get disabled message for persona
String _getDisabledMessage(PersonaId persona, int? freeUsesLeft, double? balance, int? hearts) {
  if (persona == PersonaId.basis && freeUsesLeft != null && freeUsesLeft <= 0) {
    if (hearts == null || hearts < 1) {
      return '🐱 Кот Базис устал сегодня и нет сердец. Пополните сердца!';
    }
    return '🐱 Кот Базис устал сегодня. Используйте сердце для оплаты!';
  }
  if (balance != null && persona.cost > balance!) {
    final cost = persona.cost.toStringAsFixed(0);
    final currentBalance = balance!.toStringAsFixed(2);
    if (hearts == null || hearts < 1) {
      return '💰 Недостаточно средств. Нужно ${cost} ₽, на счету ${currentBalance} ₽';
    }
    return '💰 Недостаточно средств (${currentBalance} ₽). Используйте сердце или пополните баланс!';
  }
  return '';
}

/// Show persona selection dialog
/// Returns selected PersonaId or null if cancelled
/// Note: useHearts is determined automatically by the caller based on hearts availability
Future<PersonaId?> showPersonaSelectorDialog(
  BuildContext context,
  WidgetRef ref, {
  PersonaId defaultPersona = PersonaId.petrovich,
  String title = 'Выберите AI',
  int? freeUsesLeft,
  double? balance,
  int? hearts,
}) async {
  PersonaId selected = defaultPersona;

  return await showDialog<PersonaId>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isSelectionDisabled = _isSelectionDisabled(selected, freeUsesLeft, balance, hearts);
        final disabledMessage = _getDisabledMessage(selected, freeUsesLeft, balance, hearts);
        final isInsufficientBalance = balance != null && selected.cost > balance! && selected != PersonaId.basis;
        final canUseHearts = hearts != null && hearts >= 1;
        
        return AlertDialog(
          title: Text(title),
          content: PersonaSelector(
            selectedPersona: selected,
            freeUsesLeft: freeUsesLeft,
            balance: balance,
            hearts: hearts,
            onPersonaSelected: (persona) {
              setState(() => selected = persona);
            },
            onDisabledPersonaTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(disabledMessage.isNotEmpty 
                      ? disabledMessage 
                      : 'Персонаж недоступен'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            if (isInsufficientBalance && !canUseHearts)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showTopUpDialog(context, ref);
                },
                child: const Text('Пополнить'),
              ),
            FilledButton(
              onPressed: isSelectionDisabled
                  ? null
                  : () => Navigator.pop(context, selected),
              child: Text(isSelectionDisabled ? 'Недоступно' : 'Выбрать'),
            ),
          ],
        );
      },
    ),
  );
}

/// Simple persona selection bottom sheet
/// Returns selected PersonaId or null if cancelled
/// Note: useHearts is determined automatically by the caller based on hearts availability
Future<PersonaId?> showPersonaSheet(
  BuildContext context,
  WidgetRef ref, {
  PersonaId defaultPersona = PersonaId.petrovich,
  int? freeUsesLeft,
  double? balance,
  int? hearts,
}) async {
  PersonaId selected = defaultPersona;

  return await showModalBottomSheet<PersonaId>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isSelectionDisabled = _isSelectionDisabled(selected, freeUsesLeft, balance, hearts);
        final disabledMessage = _getDisabledMessage(selected, freeUsesLeft, balance, hearts);
        final isInsufficientBalance = balance != null && selected.cost > balance! && selected != PersonaId.basis;
        final canUseHearts = hearts != null && hearts >= 1;
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonaSelector(
                selectedPersona: selected,
                freeUsesLeft: freeUsesLeft,
                balance: balance,
                hearts: hearts,
                onPersonaSelected: (persona) {
                  setState(() => selected = persona);
                },
                onDisabledPersonaTap: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(disabledMessage.isNotEmpty 
                          ? disabledMessage 
                          : 'Персонаж недоступен'),
                      duration: const Duration(seconds: 2),
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
                    disabledMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Free bonus info when hearts available
              if (canUseHearts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard, size: 18, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '🎁 Бесплатный бонус: 1❤️ будет использован',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Top up button for insufficient balance (without hearts)
              if (isInsufficientBalance && !canUseHearts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showTopUpDialog(context, ref);
                      },
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Пополнить счет'),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSelectionDisabled
                      ? null
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
