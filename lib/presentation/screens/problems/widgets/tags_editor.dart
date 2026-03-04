import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/problem.dart';
import '../../../providers/problems_provider.dart';

/// Shows bottom sheet for editing tags
Future<void> showTagsEditorDialog({
  required BuildContext context,
  required List<TagModel> currentTags,
  required Function(List<String>) onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _TagsEditorSheet(
      initialTags: currentTags.map((t) => t.name).toList(),
      onSaved: onSaved,
    ),
  );
}

/// Tags editor bottom sheet
class _TagsEditorSheet extends ConsumerStatefulWidget {
  final List<String> initialTags;
  final Function(List<String>) onSaved;

  const _TagsEditorSheet({
    required this.initialTags,
    required this.onSaved,
  });

  @override
  ConsumerState<_TagsEditorSheet> createState() => _TagsEditorSheetState();
}

class _TagsEditorSheetState extends ConsumerState<_TagsEditorSheet> {
  late List<String> _selectedTags;
  late final TextEditingController _tagController;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() => _selectedTags.add(tag));
    }
    _tagController.clear();
    setState(() => _showSuggestions = false);
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  void _save() {
    widget.onSaved(_selectedTags);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = _tagController.text.isNotEmpty
        ? ref.watch(tagsProvider(_tagController.text))
        : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sell_outlined, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Редактировать теги',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selected tags chips
            if (_selectedTags.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _selectedTags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Tag input with search
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Поиск или создание тега',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_tagController.text.isNotEmpty) {
                      _addTag(_tagController.text.trim());
                    }
                  },
                ),
              ),
              onChanged: (value) {
                setState(() => _showSuggestions = value.isNotEmpty);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addTag(value.trim());
                }
              },
            ),

            // Tag suggestions dropdown
            if (_showSuggestions && tagsAsync != null)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: tagsAsync.when(
                  data: (tags) {
                    final availableTags = tags
                        .where((t) => !_selectedTags.contains(t.name))
                        .take(5)
                        .toList();

                    if (availableTags.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Нет предложений. Нажмите + для создания.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.only(top: 4),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableTags.length,
                        itemBuilder: (context, index) {
                          final tag = availableTags[index];
                          final isPending = tag.isPending;
                          
                          return ListTile(
                            dense: true,
                            title: Row(
                              children: [
                                Expanded(child: Text(tag.name)),
                                if (isPending) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'на модерации',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.add, size: 18),
                            onTap: () => _addTag(tag.name),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Сохранить теги'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
