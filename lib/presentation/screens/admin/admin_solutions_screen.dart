import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../widgets/shared/adaptive_layout.dart';
import '../../widgets/shared/markdown_with_math.dart';
import '../../widgets/shared/image_viewer.dart';
import '../../widgets/shared/math_zoom_dialog.dart';

/// Solutions moderation screen
class AdminSolutionsScreen extends ConsumerWidget {
  const AdminSolutionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solutionsNotifierProvider);

    // Автозагрузка при первом входе
    if (!state.isLoading && state.solutions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(solutionsNotifierProvider.notifier).load();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('✍️ Модерация решений'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(solutionsNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: AdaptiveLayout(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(child: Text('Ошибка: ${state.error}'))
                : state.solutions.isEmpty
                    ? const Center(child: Text('📭 Нет решений на модерации'))
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Row(
                              children: [
                                Text('📊 Решений: ${state.total}'),
                                const Spacer(),
                                TextButton.icon(
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Одобрить все'),
                                  onPressed: () => _approveAll(context, ref),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.solutions.length,
                              itemBuilder: (context, index) {
                                final solution = state.solutions[index];
                                return _SolutionTile(solution: solution);
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Одобрить все?'),
        content: Text('Одобрить все ${ref.read(solutionsNotifierProvider).solutions.length} решений?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Одобрить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final count = await ref.read(solutionsNotifierProvider.notifier).approveAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Одобрено: $count решений')),
        );
      }
    }
  }
}

class _SolutionTile extends ConsumerWidget {
  final AdminSolution solution;

  const _SolutionTile({required this.solution});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = solution.status == 'completed'
        ? Colors.green
        : solution.status == 'in_progress'
            ? Colors.blue
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${solution.id}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icons for text/image
                Icon(
                  Icons.text_snippet_outlined,
                  size: 16,
                  color: solution.solutionText != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: solution.hasImage ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    solution.status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            // Problem info
            if (solution.problem != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${solution.problem!.source?.name ?? "???"}: ${solution.problem!.reference ?? "#${solution.problem!.id}"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Solution preview
            if (solution.solutionText != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  solution.solutionText!.length > 150
                      ? '${solution.solutionText!.substring(0, 150)}...'
                      : solution.solutionText!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            
            // Author
            if (solution.addedBy != null) ...[
              const SizedBox(height: 4),
              Text(
                '👤 ${solution.addedBy!.displayName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            
            // Actions
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Детали'),
                  onPressed: () => _showDetails(context, ref),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  label: const Text('Удалить'),
                  onPressed: () => _delete(context, ref),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.close, color: Colors.orange, size: 18),
                  label: const Text('Отклонить'),
                  onPressed: () => _reject(context, ref),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Одобрить'),
                  onPressed: () => _approve(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(solutionsNotifierProvider.notifier).approve(solution.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Решение #${solution.id} одобрено' : 'Ошибка'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(solutionsNotifierProvider.notifier).reject(solution.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Решение #${solution.id} отклонено' : 'Ошибка'),
          backgroundColor: result ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить решение?'),
        content: const Text('Это действие необратимо. Будут удалены все связанные данные.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref.read(solutionsNotifierProvider.notifier).delete(solution.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'Решение #${solution.id} удалено' : 'Ошибка'),
            backgroundColor: result ? Colors.red : Colors.grey,
          ),
        );
      }
    }
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SolutionModerationDetailScreen(solutionId: solution.id),
      ),
    );
  }
}

/// Screen for viewing detailed solution info for moderation
class _SolutionModerationDetailScreen extends ConsumerStatefulWidget {
  final int solutionId;

  const _SolutionModerationDetailScreen({required this.solutionId});

  @override
  ConsumerState<_SolutionModerationDetailScreen> createState() => _SolutionModerationDetailScreenState();
}

class _SolutionModerationDetailScreenState extends ConsumerState<_SolutionModerationDetailScreen> {
  SolutionModerationDetails? _details;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final details = await adminRepo.getSolutionModerationDetails(widget.solutionId);
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Решение #${widget.solutionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadDetails, child: const Text('Повторить')),
                    ],
                  ),
                )
              : _details == null
                  ? const Center(child: Text('Данные не найдены'))
                  : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final solution = _details!.solution;
    final questions = _details!.questions;
    final hints = _details!.hints;
    final epiphanies = _details!.epiphanies;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdaptiveLayout(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solution info card
            _buildSolutionInfoCard(context, solution),
            const SizedBox(height: 16),

            // Problem condition
            if (solution.problem != null) ...[
              _buildProblemCard(context, solution.problem!),
              const SizedBox(height: 16),
            ],

            // User notes
            if (solution.userNotes != null && solution.userNotes!.isNotEmpty) ...[
              _buildUserNotesCard(context, solution.userNotes!),
              const SizedBox(height: 16),
            ],

            // Solution image (shown independently of text)
            if (solution.hasImage) ...[
              _buildSolutionImageCard(context),
              const SizedBox(height: 16),
            ],

            // Solution text
            if (solution.solutionText != null && solution.solutionText!.isNotEmpty) ...[
              _buildSolutionTextCard(context, solution.solutionText!),
              const SizedBox(height: 16),
            ],

            // Questions
            if (questions.isNotEmpty) ...[
              _buildSectionHeader(context, '❓ Вопросы', questions.length),
              ...questions.map((q) => _buildQuestionCard(context, q)),
              const SizedBox(height: 16),
            ],

            // Hints
            if (hints.isNotEmpty) ...[
              _buildSectionHeader(context, '💡 Подсказки', hints.length),
              ...hints.map((h) => _buildHintCard(context, h)),
              const SizedBox(height: 16),
            ],

            // Epiphanies
            if (epiphanies.isNotEmpty) ...[
              _buildSectionHeader(context, '✨ Озарения', epiphanies.length),
              ...epiphanies.map((e) => _buildEpiphanyCard(context, e)),
            ],

            // Actions at bottom
            const SizedBox(height: 24),
            _buildActionsCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSolutionInfoCard(BuildContext context, AdminSolutionDetail solution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 Информация о решении', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _buildInfoRow(context, 'ID', '#${solution.id}'),
            _buildInfoRow(context, 'Статус', solution.status),
            _buildInfoRow(context, 'Модерация', solution.moderationStatus),
            if (solution.personalDifficulty != null)
              _buildInfoRow(context, 'Сложность', '${solution.personalDifficulty}/5'),
            if (solution.qualityScore != null)
              _buildInfoRow(context, 'Качество', '${solution.qualityScore!.toStringAsFixed(1)}/1.0'),
            if (solution.totalMinutes != null)
              _buildInfoRow(context, 'Время', '${solution.totalMinutes!.toStringAsFixed(0)} мин'),
            if (solution.xpEarned != null)
              _buildInfoRow(context, 'XP', '+${solution.xpEarned!.toStringAsFixed(0)}'),
            if (solution.user != null)
              _buildInfoRow(context, 'Пользователь', solution.user!.displayName),
            _buildInfoRow(context, 'Изображение', solution.hasImage ? '✓ Есть' : '✗ Нет'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemCard(BuildContext context, AdminProblemDetail problem) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 20),
                const SizedBox(width: 8),
                Text('📝 Задача', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (problem.source != null)
              _buildInfoRow(context, 'Источник', problem.source!.name),
            if (problem.reference != null)
              _buildInfoRow(context, 'Номер', problem.reference!),
            _buildInfoRow(context, 'Изображение', problem.hasImage ? '✓ Есть' : '✗ Нет'),
            if (problem.conditionText != null && problem.conditionText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Условие:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownWithMath(
                  text: problem.conditionText!,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  onFormulaTap: (latex) {
                    MathZoomDialog.show(context, latex: latex);
                  },
                ),
              ),
            ],
            if (problem.hasImage) ...[
              const SizedBox(height: 12),
              ConditionImageThumbnail(
                problemId: problem.id,
                title: 'Условие задачи',
                height: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserNotesCard(BuildContext context, String notes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_outlined, size: 20),
                const SizedBox(width: 8),
                Text('📝 Заметки пользователя', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            MarkdownWithMath(
              text: notes,
              textStyle: Theme.of(context).textTheme.bodyMedium,
              onFormulaTap: (latex) {
                MathZoomDialog.show(context, latex: latex);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionImageCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 20),
                const SizedBox(width: 8),
                Text('📷 Фото решения', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            SolutionImageThumbnail(
              solutionId: widget.solutionId,
              title: 'Фото решения',
              height: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionTextCard(BuildContext context, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet_outlined, size: 20),
                const SizedBox(width: 8),
                Text('✍️ Текст решения', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            MarkdownWithMath(
              text: text,
              textStyle: Theme.of(context).textTheme.bodyMedium,
              onFormulaTap: (latex) {
                MathZoomDialog.show(context, latex: latex);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, AdminQuestionDetail question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#${question.id}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Icon(
                  question.hasImage ? Icons.image : Icons.text_fields,
                  size: 16,
                  color: question.hasImage ? Colors.green : Colors.grey,
                ),
              ],
            ),
            if (question.body != null && question.body!.isNotEmpty) ...[
              const SizedBox(height: 8),
              MarkdownWithMath(
                text: question.body!,
                textStyle: Theme.of(context).textTheme.bodyMedium,
                onFormulaTap: (latex) {
                  MathZoomDialog.show(context, latex: latex);
                },
              ),
            ],
            if (question.answer != null && question.answer!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ответ:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    MarkdownWithMath(
                      text: question.answer!,
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      onFormulaTap: (latex) {
                        MathZoomDialog.show(context, latex: latex);
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (question.hasImage) ...[
              const SizedBox(height: 8),
              QuestionImageThumbnail(
                questionId: question.id,
                title: 'Изображение вопроса',
                height: 150,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard(BuildContext context, AdminHintDetail hint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#${hint.id}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Icon(
                  hint.hasImage ? Icons.image : Icons.lightbulb_outline,
                  size: 16,
                  color: hint.hasImage ? Colors.green : Colors.orange,
                ),
                if (hint.status != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hint.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hint.status ?? '',
                      style: TextStyle(
                        color: hint.status == 'completed' ? Colors.green : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                if (hint.xpPenalty != null) ...[
                  const SizedBox(width: 8),
                  Text('-${hint.xpPenalty} XP', style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
            if (hint.hintText != null && hint.hintText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              MarkdownWithMath(
                text: hint.hintText!,
                textStyle: Theme.of(context).textTheme.bodyMedium,
                onFormulaTap: (latex) {
                  MathZoomDialog.show(context, latex: latex);
                },
              ),
            ],
            if (hint.userNotes != null && hint.userNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Заметки:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(hint.userNotes!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            if (hint.hasImage) ...[
              const SizedBox(height: 8),
              HintImageThumbnail(
                hintId: hint.id,
                title: 'Контекст подсказки',
                height: 150,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEpiphanyCard(BuildContext context, AdminEpiphanyDetail epiphany) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#${epiphany.id}', style: const TextStyle(color: Colors.purple, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Icon(
                  epiphany.hasImage ? Icons.image : Icons.auto_awesome,
                  size: 16,
                  color: epiphany.hasImage ? Colors.green : Colors.purple,
                ),
                if (epiphany.magnitude != null) ...[
                  const SizedBox(width: 8),
                  ...List.generate(
                    epiphany.magnitude!.clamp(1, 5),
                    (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                  ),
                ],
              ],
            ),
            if (epiphany.description != null && epiphany.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              MarkdownWithMath(
                text: epiphany.description!,
                textStyle: Theme.of(context).textTheme.bodyMedium,
                onFormulaTap: (latex) {
                  MathZoomDialog.show(context, latex: latex);
                },
              ),
            ],
            if (epiphany.hasImage) ...[
              const SizedBox(height: 8),
              EpiphanyImageThumbnail(
                epiphanyId: epiphany.id,
                title: 'Изображение озарения',
                height: 150,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await ref.read(solutionsNotifierProvider.notifier).reject(widget.solutionId);
                      if (result && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Решение отклонено')),
                        );
                      }
                    },
                    icon: const Icon(Icons.close, color: Colors.orange),
                    label: const Text('Отклонить'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await ref.read(solutionsNotifierProvider.notifier).approve(widget.solutionId);
                      if (result && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Решение одобрено')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Одобрить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
