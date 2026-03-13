import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/artifacts.dart';
import '../../providers/admin_provider.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/shared/persona_selector.dart';
import '../../widgets/shared/adaptive_layout.dart';
import '../../../data/repositories/admin_repository.dart';

/// Deduplication management screen
class AdminDedupScreen extends ConsumerStatefulWidget {
  const AdminDedupScreen({super.key});

  @override
  ConsumerState<AdminDedupScreen> createState() => _AdminDedupScreenState();
}

class _AdminDedupScreenState extends ConsumerState<AdminDedupScreen> {
  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dedupNotifierProvider.notifier).loadCandidates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dedupNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧹 Дедупликация концептов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dedupNotifierProvider.notifier).loadCandidates(
                  statusFilter: _statusFilter,
                ),
          ),
        ],
      ),
      body: AdaptiveLayout(
        child: Column(
          children: [
            // Stats from last run
            if (state.lastResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.green.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 Результат последнего запуска:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Активных: ${state.lastResult!.totalActiveConcepts} | '
                      'Слито: ${state.lastResult!.totalMergedAliases} | '
                      'Кандидатов: ${state.lastResult!.candidatesCreated} | '
                      'Auto: ${state.lastResult!.autoApproved} | '
                      'Pending: ${state.lastResult!.pendingReview}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],

            // Filter chips
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('Ожидают (${state.pendingCount})'),
                    selected: _statusFilter == 'pending',
                    onSelected: (_) => _setFilter('pending'),
                  ),
                  FilterChip(
                    label: const Text('Auto-approved'),
                    selected: _statusFilter == 'auto_approved',
                    onSelected: (_) => _setFilter('auto_approved'),
                  ),
                  FilterChip(
                    label: const Text('Все'),
                    selected: _statusFilter == 'all',
                    onSelected: (_) => _setFilter('all'),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Запустить дедуп'),
                      onPressed: () => _runDedup(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: const Text('Применить auto'),
                      onPressed: state.isLoading ? null : _applyAutoApproved,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Candidates list
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Ошибка: ${state.error}'))
                      : state.candidates.isEmpty
                          ? const Center(child: Text('📭 Нет кандидатов'))
                          : ListView.builder(
                              itemCount: state.candidates.length,
                              itemBuilder: (context, index) {
                                return _CandidateCard(
                                  candidate: state.candidates[index],
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _setFilter(String filter) {
    setState(() => _statusFilter = filter);
    ref.read(dedupNotifierProvider.notifier).loadCandidates(statusFilter: filter);
  }

  Future<void> _runDedup(BuildContext context) async {
    final billing = ref.read(billingBalanceProvider);
    final persona = await showPersonaSheet(
      context,
      ref,
      defaultPersona: PersonaId.legendre,
      freeUsesLeft: billing.value?.freeUsesLeft,
      balance: billing.value?.balance,
      hearts: null, // Дедупликация только за деньги
    );

    if (persona != null && context.mounted) {
      final result = await ref.read(dedupNotifierProvider.notifier).runDeduplication(persona.name);
      if (context.mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Создано кандидатов: ${result.candidatesCreated}\n'
                'Auto-approved: ${result.autoApproved}\n'
                'Pending: ${result.pendingReview}',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка запуска дедупликации')),
          );
        }
      }
    }
  }

  Future<void> _applyAutoApproved() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Применить все auto-approved?'),
        content: const Text('Все автоматически одобренные кандидаты будут склеены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Применить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final count = await ref.read(dedupNotifierProvider.notifier).applyAutoApproved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Применено: $count кандидатов')),
        );
      }
    }
  }
}

class _CandidateCard extends ConsumerWidget {
  final DedupCandidate candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Confidence color
    Color confColor;
    if (candidate.confidence >= 0.95) {
      confColor = Colors.green;
    } else if (candidate.confidence >= 0.7) {
      confColor = Colors.orange;
    } else {
      confColor = Colors.red;
    }

    // Classification icon
    final classIcon = candidate.classification == 'IDENTICAL' ? '≡' : '≈';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: confColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${candidate.id}',
                    style: TextStyle(color: confColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$classIcon ${candidate.classification}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: confColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(candidate.confidence * 100).toInt()}%',
                    style: TextStyle(color: confColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Canonical concept
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '[${candidate.canonicalConcept.id}] ${candidate.canonicalConcept.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${candidate.canonicalUsageCount})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            // Proposed aliases
            ...candidate.proposedAliases.map((alias) => Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '[${alias.id}] ${alias.name}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${alias.usageCount})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )),

            // Reason
            if (candidate.reason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        candidate.reason!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Total usage
            const SizedBox(height: 4),
            Text(
              '📈 Всего использований: канонический ${candidate.canonicalUsageCount} + алиасы ${candidate.aliasesUsageCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),

            // Actions
            if (candidate.status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.orange),
                    label: const Text('Отклонить'),
                    onPressed: () => _reject(context, ref),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    label: const Text('С коррекцией'),
                    onPressed: () => _approveWithRename(context, ref),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Мерж'),
                    onPressed: () => _approve(context, ref),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(dedupNotifierProvider.notifier).approve(candidate.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Склеено' : 'Ошибка'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _approveWithRename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: candidate.canonicalNameCorrection ?? candidate.canonicalConcept.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новое название'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название канонического концепта',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && context.mounted) {
      final result = await ref.read(dedupNotifierProvider.notifier).approve(
            candidate.id,
            newName: newName,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'Склеено с переименованием' : 'Ошибка'),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить склейку?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина (опционально)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref.read(dedupNotifierProvider.notifier).reject(
            candidate.id,
            reason: reasonController.text.isNotEmpty ? reasonController.text : null,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'Отклонено' : 'Ошибка'),
            backgroundColor: result ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }
}
