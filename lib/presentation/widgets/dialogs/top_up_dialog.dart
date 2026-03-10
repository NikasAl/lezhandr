import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, launchUrlString, LaunchMode;
import '../../providers/billing_provider.dart';

/// Data class for top-up amount options
class _TopUpAmount {
  final int amount;
  final String emoji;
  final String label;

  const _TopUpAmount(this.amount, this.emoji, this.label);
}

/// Card widget for selecting a top-up amount
class _TopUpAmountCard extends StatelessWidget {
  final _TopUpAmount item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopUpAmountCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.amount} ₽',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show top-up dialog for balance replenishment
void showTopUpDialog(BuildContext context, WidgetRef ref) {
  final amounts = [
    _TopUpAmount(50, '☕', 'Кофе'),
    _TopUpAmount(100, '🍔', 'Обед'),
    _TopUpAmount(300, '📚', 'Учеба'),
    _TopUpAmount(500, '🎯', 'Про'),
    _TopUpAmount(1000, '🚀', 'Хардкор'),
    _TopUpAmount(3000, '👑', 'Легенда'),
  ];
  int? selectedAmount;
  final customController = TextEditingController();
  bool isCustom = false;
  bool isLoading = false;
  final billing = ref.read(billingBalanceProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Пополнение баланса',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Текущий баланс: ${billing.value?.balance.toStringAsFixed(2) ?? '0.00'} ₽',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preset amounts grid
                    Text(
                      'Выберите сумму',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                      children: amounts.map((item) {
                        final isSelected = !isCustom && selectedAmount == item.amount;
                        return _TopUpAmountCard(
                          item: item,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedAmount = item.amount;
                              isCustom = false;
                              customController.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Custom amount
                    Text(
                      'Или введите сумму',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Своя сумма',
                        hintText: 'От 10 до 50000 ₽',
                        prefixIcon: const Icon(Icons.edit_outlined),
                        suffixText: '₽',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: isCustom,
                        fillColor: isCustom 
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : null,
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        setState(() {
                          if (parsed != null && parsed >= 10) {
                            selectedAmount = parsed;
                            isCustom = true;
                          } else {
                            isCustom = false;
                          }
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Оплата через ЮKassa. Средства зачисляются мгновенно после оплаты. Получатель https://kreagenium.ru',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => Navigator.pop(sheetContext),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: selectedAmount == null || isLoading
                                ? null
                                : () async {
                                    setState(() => isLoading = true);
                                    try {
                                      final response = await ref
                                          .read(billingNotifierProvider.notifier)
                                          .createTopUp(selectedAmount!.toDouble());

                                      if (response != null && response.paymentUrl.isNotEmpty) {
                                        Navigator.pop(sheetContext);

                                        final paymentUrl = response.paymentUrl;
                                        final uri = Uri.parse(paymentUrl);
                                        debugPrint('🔗 Payment URL: $paymentUrl');
                                        debugPrint('🔗 Parsed URI: $uri');
                                        debugPrint('🔗 URI scheme: ${uri.scheme}, host: ${uri.host}');
                                        
                                        bool launched = false;
                                        
                                        // Try different launch methods
                                        // Method 1: externalApplication
                                        try {
                                          launched = await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                          debugPrint('🔗 Method 1 - externalApplication: $launched');
                                        } catch (e) {
                                          debugPrint('❌ Method 1 error: $e');
                                        }
                                        
                                        // Method 2: inAppBrowserView (Chrome Custom Tabs)
                                        if (!launched) {
                                          try {
                                            launched = await launchUrl(
                                              uri,
                                              mode: LaunchMode.inAppBrowserView,
                                            );
                                            debugPrint('🔗 Method 2 - inAppBrowserView: $launched');
                                          } catch (e) {
                                            debugPrint('❌ Method 2 error: $e');
                                          }
                                        }
                                        
                                        // Method 3: platformDefault
                                        if (!launched) {
                                          try {
                                            launched = await launchUrl(uri);
                                            debugPrint('🔗 Method 3 - platformDefault: $launched');
                                          } catch (e) {
                                            debugPrint('❌ Method 3 error: $e');
                                          }
                                        }
                                        
                                        // Method 4: launchUrlString
                                        if (!launched) {
                                          try {
                                            launched = await launchUrlString(
                                              paymentUrl,
                                              mode: LaunchMode.externalApplication,
                                            );
                                            debugPrint('🔗 Method 4 - launchUrlString: $launched');
                                          } catch (e) {
                                            debugPrint('❌ Method 4 error: $e');
                                          }
                                        }
                                        
                                        if (!launched && context.mounted) {
                                          // Fallback: show dialog with URL to copy
                                          _showPaymentUrlDialog(
                                            context,
                                            ref,
                                            paymentUrl: response.paymentUrl,
                                            invoiceId: response.invoiceId,
                                            amount: selectedAmount!,
                                          );
                                          return;
                                        }

                                        if (launched && context.mounted) {
                                          _showPaymentWaitingDialog(
                                            context,
                                            ref,
                                            invoiceId: response.invoiceId,
                                            amount: selectedAmount!,
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Ошибка создания платежа'),
                                            ),
                                          );
                                        }
                                      }
                                    } finally {
                                      if (sheetContext.mounted) {
                                        setState(() => isLoading = false);
                                      }
                                    }
                                  },
                            icon: isLoading 
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.payment),
                            label: Text(isLoading ? 'Обработка...' : 'Оплатить ${selectedAmount != null ? '$selectedAmount ₽' : ''}'),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom padding for safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Show dialog waiting for payment completion
void _showPaymentWaitingDialog(BuildContext context, WidgetRef ref, {
  required String invoiceId,
  required int amount,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Row(
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
            'Счёт на $amount ₽ создан',
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
          const SizedBox(height: 8),
          Text(
            'ID: $invoiceId',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            // Open payment URL again
            final response = await ref
                .read(billingNotifierProvider.notifier)
                .createTopUp(amount.toDouble());
            if (response != null && response.paymentUrl.isNotEmpty) {
              final uri = Uri.parse(response.paymentUrl);
              try {
                final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!launched) {
                  await launchUrl(uri);
                }
              } catch (e) {
                debugPrint('❌ Launch error: $e');
              }
            }
          },
          icon: const Icon(Icons.open_in_browser, size: 18),
          label: const Flexible(child: Text('Открыть снова')),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            // Refresh balance
            ref.invalidate(billingBalanceProvider);
          },
          icon: const Icon(Icons.check),
          label: const Text('Готово'),
        ),
      ],
    ),
  );
}

/// Fallback dialog when browser cannot be launched - allows copying URL
void _showPaymentUrlDialog(BuildContext context, WidgetRef ref, {
  required String paymentUrl,
  required String invoiceId,
  required int amount,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Row(
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
            'Счёт на $amount ₽ создан',
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
          const SizedBox(height: 8),
          Text(
            'ID: $invoiceId',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
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
          label: const Flexible(child: Text('Копировать')),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            // Refresh balance
            ref.invalidate(billingBalanceProvider);
          },
          icon: const Icon(Icons.check),
          label: const Text('Готово'),
        ),
      ],
    ),
  );
}
