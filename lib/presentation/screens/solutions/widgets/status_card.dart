import 'package:flutter/material.dart';
import '../../../../data/models/solution.dart';
import '../../../../data/models/user.dart';

/// Status card showing solution status and stats
class SolutionStatusCard extends StatefulWidget {
  final SolutionModel solution;
  final UserPublicProfile? addedBy;
  final bool isOwner;
  final Future<bool> Function(int solutionId, String notes)? onUpdateNotes;

  const SolutionStatusCard({
    super.key,
    required this.solution,
    this.addedBy,
    this.isOwner = false,
    this.onUpdateNotes,
  });

  @override
  State<SolutionStatusCard> createState() => _SolutionStatusCardState();
}

class _SolutionStatusCardState extends State<SolutionStatusCard> {
  bool _isEditingNotes = false;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    if (widget.onUpdateNotes == null) return;
    
    setState(() => _isSaving = true);
    
    final success = await widget.onUpdateNotes!(
      widget.solution.id,
      _notesController.text.trim(),
    );
    
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _isEditingNotes = false;
        }
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заметка сохранена'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка сохранения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.solution.isCompleted
                      ? Icons.check_circle
                      : widget.solution.isActive
                          ? Icons.timer
                          : Icons.pause_circle,
                  color: widget.solution.isCompleted
                      ? Colors.green
                      : widget.solution.isActive
                          ? Colors.blue
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.solution.statusText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          // Moderation status badge
                          if (widget.solution.isPending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'на модерации',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ] else if (widget.solution.isRejected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'отклонено',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.addedBy != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.addedBy!.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(
                  icon: Icons.timer_outlined,
                  label: '${widget.solution.totalMinutes.toStringAsFixed(0)} мин',
                  tooltip: 'За сколько времени была решена эта задача',
                ),
                if (widget.solution.xpEarned != null)
                  StatChip(
                    icon: Icons.star,
                    label: '${widget.solution.xpEarned!.toStringAsFixed(0)} XP',
                    color: Colors.amber,
                    tooltip: 'Сколько XP было получено за эту задачу',
                  ),
                if (widget.solution.personalDifficulty != null)
                  StatChip(
                    icon: Icons.fitness_center,
                    label: '${widget.solution.personalDifficulty} / 5',
                    tooltip: 'Субъективная сложность задачи по шкале от 1 до 5',
                  ),
              ],
            ),
            
            // User notes section
            if (widget.isOwner || (widget.solution.userNotes != null && widget.solution.userNotes!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Заметка',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (widget.isOwner && !_isEditingNotes) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Редактировать',
                      onPressed: () {
                        setState(() {
                          _isEditingNotes = true;
                          _notesController.text = widget.solution.userNotes ?? '';
                        });
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              
              if (_isEditingNotes) ...[
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Ваши заметки к решению...',
                    border: const OutlineInputBorder(),
                    counterText: '${_notesController.text.length}/500',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () {
                        setState(() => _isEditingNotes = false);
                      },
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveNotes,
                      icon: _isSaving 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Сохранить'),
                    ),
                  ],
                ),
              ] else if (widget.solution.userNotes != null && widget.solution.userNotes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.solution.userNotes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ] else if (widget.isOwner) ...[
                Text(
                  'Нажмите ✏️ чтобы добавить заметку',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Stat chip widget for displaying metrics with tooltip
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final String? tooltip;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
            ),
          ),
        ],
      ),
    );

    // If tooltip is provided, make it interactive
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: false,
        verticalOffset: 0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Show snackbar with tooltip for better visibility
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tooltip!),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                ),
              );
            },
            child: chip,
          ),
        ),
      );
    }

    return chip;
  }
}
