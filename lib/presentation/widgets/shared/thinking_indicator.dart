import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/models/artifacts.dart';

/// Animated "thinking" widget that shows persona-specific messages
/// Displays rotating messages while an AI operation is in progress
class ThinkingIndicator extends StatefulWidget {
  final PersonaId persona;
  final String? customMessage;

  const ThinkingIndicator({
    super.key,
    required this.persona,
    this.customMessage,
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _messageTimer;
  int _messageIndex = 0;
  
  late final List<String> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _getMessagesForPersona(widget.persona);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _startMessageRotation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startMessageRotation() {
    if (_messages.length <= 1) return;
    
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  List<String> _getMessagesForPersona(PersonaId persona) {
    switch (persona) {
      case PersonaId.basis:
        return [
          'Мрр... Щас подумаем...',
          'Мяяу... Это интересно...',
          'Мур-мур... А можно я полежу ещё немного?',
          'Котики тоже умеют думать... иногда...',
          'Мррр... Почти придумал...',
        ];
      case PersonaId.petrovich:
        return [
          'Щас глянем, чё тут...',
          'Дай-ка подумать, милок...',
          'А ведь тут хитро придумано!',
          'Ну-ну, интересно...',
          'Сейчас разберёмся, не спеши...',
          'Ага, вижу вижу...',
        ];
      case PersonaId.legendre:
        return [
          'Анализирую задачу...',
          'Применяю математический аппарат...',
          'Выстраиваю логическую цепочку...',
          'Проверяю гипотезы...',
          'Формулирую решение...',
          'Ищу оптимальный подход...',
        ];
    }
  }

  String get _emoji {
    switch (widget.persona) {
      case PersonaId.basis:
        return '🐱';
      case PersonaId.petrovich:
        return '🧹';
      case PersonaId.legendre:
        return '🧐';
    }
  }

  Color get _accentColor {
    switch (widget.persona) {
      case PersonaId.basis:
        return Colors.orange;
      case PersonaId.petrovich:
        return Colors.brown;
      case PersonaId.legendre:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated emoji
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 0.1 - 0.05,
                    child: Transform.scale(
                      scale: 1.0 + _animationController.value * 0.1,
                      child: Text(
                        _emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Pulsing dots
              _PulsingDots(color: _accentColor),
            ],
          ),
          const SizedBox(height: 8),
          // Rotating message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.customMessage ?? _messages[_messageIndex],
              key: ValueKey(_messageIndex),
              style: TextStyle(
                color: _accentColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dots animation
class _PulsingDots extends StatelessWidget {
  final Color color;

  const _PulsingDots({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + index * 200),
          builder: (context, value, child) {
            return Opacity(
              opacity: 0.4 + (value * 0.6),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
          onEnd: () {},
        );
      }),
    );
  }
}

/// Overlay widget that shows thinking indicator while an async operation runs
/// Automatically dismisses when the operation completes
class ThinkingOverlay {
  /// Show thinking overlay and return a function to hide it
  static OverlayEntry? show(
    BuildContext context, {
    required PersonaId persona,
    String? customMessage,
  }) {
    final overlay = Overlay.of(context);
    
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: ThinkingIndicator(
            persona: persona,
            customMessage: customMessage,
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    return overlayEntry;
  }
  
  /// Hide the thinking overlay
  static void hide(OverlayEntry? entry) {
    entry?.remove();
  }
}

/// Thinking message with cancel option for very long operations
class ThinkingWithCancel extends StatelessWidget {
  final PersonaId persona;
  final VoidCallback onCancel;
  final int elapsedSeconds;

  const ThinkingWithCancel({
    super.key,
    required this.persona,
    required this.onCancel,
    this.elapsedSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    final timeStr = minutes > 0 
        ? '${minutes}м ${seconds}с'
        : '${seconds}с';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThinkingIndicator(persona: persona),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прошло: $timeStr',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Отменить'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
