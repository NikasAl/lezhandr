import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/billing.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/shared/error_display.dart';
import '../../../utils/url_opener.dart';

/// Transactions screen - list of all transactions (income/expense)
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _currentOffset = 0;
  final int _pageSize = 20;
  
  // Accumulated transactions list for infinite scroll
  List<TransactionModel> _accumulatedTransactions = [];
  int _totalTransactions = 0;
  bool _hasMore = true;

  void _resetPagination() {
    _currentOffset = 0;
    _accumulatedTransactions = [];
    _totalTransactions = 0;
    _hasMore = true;
  }

  @override
  Widget build(BuildContext context) {
    final filter = TransactionsFilter(
      limit: _pageSize,
      offset: _currentOffset,
    );

    final transactionsAsync = ref.watch(transactionsListProvider(filter));

    // Update accumulated list when new data arrives
    transactionsAsync.whenData((response) {
      if (_currentOffset == 0) {
        _accumulatedTransactions = response.items;
      } else if (_accumulatedTransactions.length < _currentOffset + response.items.length) {
        final existingIds = _accumulatedTransactions.map((t) => t.id).toSet();
        final newItems = response.items.where((t) => !existingIds.contains(t.id)).toList();
        _accumulatedTransactions = [..._accumulatedTransactions, ...newItems];
      }
      _totalTransactions = response.total;
      _hasMore = response.hasMore;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакции'),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  'Приход',
                  _calculateTotalIncome(),
                  Colors.green,
                  Icons.arrow_downward,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                _buildSummaryItem(
                  context,
                  'Расход',
                  _calculateTotalExpense(),
                  Colors.red,
                  Icons.arrow_upward,
                ),
              ],
            ),
          ),
          
          // Transactions list
          Expanded(
            child: transactionsAsync.when(
              data: (response) {
                final transactions = _accumulatedTransactions;
                
                if (transactions.isEmpty && _currentOffset == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет транзакций',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'История операций будет отображаться здесь',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Total count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Theme.of(context).colorScheme.surface,
                      child: Text(
                        'Всего: $_totalTransactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: transactions.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == transactions.length && _hasMore) {
                            return _LoadMoreCard(
                              isLoading: transactionsAsync.isLoading,
                              onLoadMore: () {
                                if (!transactionsAsync.isLoading) {
                                  setState(() {
                                    _currentOffset += _pageSize;
                                  });
                                }
                              },
                              remainingCount: _totalTransactions - transactions.length,
                            );
                          }
                          
                          final transaction = transactions[index];
                          return _TransactionTile(
                            transaction: transaction,
                            onPayTap: transaction.canBePaid
                                ? () => _openPaymentUrl(
                                    context,
                                    transaction.paymentUrl!,
                                    transaction.amount,
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () {
                if (_accumulatedTransactions.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _accumulatedTransactions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _accumulatedTransactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _TransactionTile(transaction: _accumulatedTransactions[index]);
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
              error: (error, _) => ErrorDisplay(
                error: error,
                onRetry: () {
                  ref.invalidate(transactionsListProvider);
                  _resetPagination();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} ₽',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _calculateTotalIncome() {
    return _accumulatedTransactions
        .where((t) => t.isIncoming && t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalExpense() {
    return _accumulatedTransactions
        .where((t) => !t.isIncoming && t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Open payment URL for pending transaction
  Future<void> _openPaymentUrl(
    BuildContext context,
    String paymentUrl,
    double amount,
  ) async {
    final launched = await UrlOpener.openUrl(paymentUrl);
    
    if (!launched && context.mounted) {
      // Fallback: show dialog to copy URL
      _showPaymentUrlDialog(context, paymentUrl, amount);
      return;
    }

    if (launched && context.mounted) {
      // Show waiting dialog
      _showPaymentWaitingDialog(context, paymentUrl, amount);
    }
  }

  /// Show dialog with payment URL for manual copy
  void _showPaymentUrlDialog(BuildContext context, String paymentUrl, double amount) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: Colors.blue),
            const SizedBox(width: 8),
            const Flexible(child: Text('Ссылка на оплату')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Счёт на ${amount.toStringAsFixed(2)} ₽',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Не удалось открыть браузер. Скопируйте ссылку и откройте её вручную:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                paymentUrl,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paymentUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ссылка скопирована'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Копировать'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  /// Show waiting dialog after opening payment URL
  void _showPaymentWaitingDialog(BuildContext context, String paymentUrl, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, color: Colors.green),
            const SizedBox(width: 8),
            const Flexible(child: Text('Оплата')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Счёт на ${amount.toStringAsFixed(2)} ₽ создан',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Завершите оплату в браузере и вернитесь в приложение',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await UrlOpener.openUrl(paymentUrl);
            },
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text('Открыть'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Refresh transactions list
              ref.invalidate(transactionsListProvider);
              ref.invalidate(billingBalanceProvider);
              _resetPagination();
            },
            icon: const Icon(Icons.check),
            label: const Text('Готово'),
          ),
        ],
      ),
    );
  }
}

/// Transaction tile widget
class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onPayTap;

  const _TransactionTile({
    required this.transaction,
    this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final formattedDate = transaction.createdAt != null
        ? dateFormat.format(transaction.createdAt!)
        : '';

    final amountColor = transaction.isIncoming ? Colors.green : Colors.red;
    final amountPrefix = transaction.isIncoming ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: transaction.isIncoming
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              transaction.typeIcon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.typeText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$amountPrefix${transaction.amount.toStringAsFixed(2)} ₽',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null && transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                transaction.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: transaction.status, canBePaid: transaction.canBePaid),
              ],
            ),
            // Кнопка оплаты для pending транзакций
            if (transaction.canBePaid) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPayTap,
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: const Text('Оплатить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        isThreeLine: transaction.description != null && transaction.description!.isNotEmpty,
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool canBePaid;

  const _StatusBadge({
    required this.status,
    this.canBePaid = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData? icon;

    switch (status) {
      case 'succeeded':
        color = Colors.green;
        text = 'Успешно';
        icon = Icons.check_circle;
        break;
      case 'pending':
        if (canBePaid) {
          color = Colors.blue;
          text = 'К оплате';
          icon = Icons.payment;
        } else {
          color = Colors.orange;
          text = 'В обработке';
          icon = Icons.hourglass_empty;
        }
        break;
      case 'canceled':
        color = Colors.red;
        text = 'Отменено';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Load more card widget
class _LoadMoreCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoadMore;
  final int remainingCount;

  const _LoadMoreCard({
    required this.isLoading,
    required this.onLoadMore,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: isLoading ? null : onLoadMore,
        borderRadius: BorderRadius.circular(12),
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
