import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/problems_provider.dart';

/// Widget for selecting tags with search and suggestions
class TagsSelector extends ConsumerStatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagsSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<TagsSelector> createState() => _TagsSelectorState();
}

class _TagsSelectorState extends ConsumerState<TagsSelector> {
  final _tagController = TextEditingController();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = _tagController.text.isNotEmpty
        ? ref.watch(tagsProvider(_tagController.text))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags chips
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.selectedTags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final newTags = List<String>.from(widget.selectedTags)..remove(tag);
                widget.onTagsChanged(newTags);
              },
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Tag input
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Поиск или создание тега',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_tagController.text.isNotEmpty) {
                  final newTag = _tagController.text.trim();
                  if (!widget.selectedTags.contains(newTag)) {
                    widget.onTagsChanged([...widget.selectedTags, newTag]);
                  }
                  _tagController.clear();
                  setState(() => _showSuggestions = false);
                }
              },
            ),
          ),
          onChanged: (value) {
            setState(() => _showSuggestions = value.isNotEmpty);
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final newTag = value.trim();
              if (!widget.selectedTags.contains(newTag)) {
                widget.onTagsChanged([...widget.selectedTags, newTag]);
              }
              _tagController.clear();
              setState(() => _showSuggestions = false);
            }
          },
        ),

        // Tag suggestions
        if (_showSuggestions && tagsAsync != null)
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: tagsAsync.when(
              data: (tags) {
                // Filter out already selected tags
                final availableTags = tags
                    .where((t) => !widget.selectedTags.contains(t.name))
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
                      return ListTile(
                        dense: true,
                        title: Text(tag.name),
                        trailing: const Icon(Icons.add, size: 18),
                        onTap: () {
                          widget.onTagsChanged([...widget.selectedTags, tag.name]);
                          _tagController.clear();
                          setState(() => _showSuggestions = false);
                        },
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
      ],
    );
  }
}
