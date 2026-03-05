import 'package:flutter/material.dart';

/// Load more card widget for pagination
class LoadMoreCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoadMore;
  final int remainingCount;

  const LoadMoreCard({
    super.key,
    required this.isLoading,
    required this.onLoadMore,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isLoading ? null : onLoadMore,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.expand_more),
                      const SizedBox(width: 8),
                      Text(
                        'Загрузить ещё ($remainingCount осталось)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
