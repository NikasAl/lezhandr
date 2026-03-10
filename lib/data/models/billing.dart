class BillingBalanceModel {
  final double balance;
  final String currency;
  final int freeUsesLeft;
  final int totalDailyLimit;

  BillingBalanceModel({
    this.balance = 0,
    this.currency = 'RUB',
    this.freeUsesLeft = 5,
    this.totalDailyLimit = 5,
  });

  factory BillingBalanceModel.fromJson(Map<String, dynamic> json) {
    return BillingBalanceModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'RUB',
      freeUsesLeft: json['free_uses_left'] as int? ?? 5,
      totalDailyLimit: json['total_daily_limit'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'currency': currency,
        'free_uses_left': freeUsesLeft,
        'total_daily_limit': totalDailyLimit,
      };

  double get freeUsesProgress =>
      totalDailyLimit > 0 ? freeUsesLeft / totalDailyLimit : 1.0;

  bool get hasFreeUses => freeUsesLeft > 0;

  bool get hasBalance => balance > 0;
}

/// Transaction type enum
enum TransactionType {
  deposit,   // Пополнение
  spend,     // Списание
  refund,    // Возврат
  manual,    // Ручная корректировка
}

/// Transaction model
class TransactionModel {
  final int id;
  final double amount;
  final TransactionType transactionType;
  final String status;
  final String? description;
  final DateTime? createdAt;
  final String? paymentId;   // ID счёта в платёжной системе
  final String? paymentUrl;  // URL для оплаты (только для pending)

  TransactionModel({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.status,
    this.description,
    this.createdAt,
    this.paymentId,
    this.paymentUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    TransactionType type = TransactionType.spend;
    if (json['transaction_type'] != null) {
      final typeStr = json['transaction_type'] as String;
      switch (typeStr) {
        case 'deposit':
          type = TransactionType.deposit;
          break;
        case 'refund':
          type = TransactionType.refund;
          break;
        case 'manual':
          type = TransactionType.manual;
          break;
        default:
          type = TransactionType.spend;
      }
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return TransactionModel(
      id: json['id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      transactionType: type,
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String?,
      createdAt: createdAt,
      paymentId: json['payment_id'] as String?,
      paymentUrl: json['payment_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'transaction_type': transactionType.name,
        'status': status,
        'description': description,
        'created_at': createdAt?.toIso8601String(),
        'payment_id': paymentId,
        'payment_url': paymentUrl,
      };

  /// Is this an incoming transaction (money added to balance)
  bool get isIncoming =>
      transactionType == TransactionType.deposit ||
      transactionType == TransactionType.refund;

  /// Is this transaction completed successfully
  bool get isCompleted => status == 'succeeded';

  /// Can this transaction be paid (pending with payment URL)
  bool get canBePaid => status == 'pending' && paymentUrl != null && paymentUrl!.isNotEmpty;

  /// Display text for transaction type
  String get typeText {
    switch (transactionType) {
      case TransactionType.deposit:
        return 'Пополнение';
      case TransactionType.spend:
        return 'Списание';
      case TransactionType.refund:
        return 'Возврат';
      case TransactionType.manual:
        return 'Корректировка';
    }
  }

  /// Icon for transaction type
  String get typeIcon {
    switch (transactionType) {
      case TransactionType.deposit:
        return '💰';
      case TransactionType.spend:
        return '💸';
      case TransactionType.refund:
        return '↩️';
      case TransactionType.manual:
        return '⚙️';
    }
  }
}

/// Response wrapper for paginated transactions list
class TransactionListResponse {
  final List<TransactionModel> items;
  final int total;
  final int limit;
  final int offset;

  TransactionListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    return TransactionListResponse(
      items: (json['items'] as List?)
          ?.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  bool get hasMore => offset + items.length < total;
}

class TopUpResponse {
  final String invoiceId;
  final String paymentUrl;

  TopUpResponse({
    required this.invoiceId,
    required this.paymentUrl,
  });

  factory TopUpResponse.fromJson(Map<String, dynamic> json) {
    return TopUpResponse(
      invoiceId: json['invoice_id'] as String? ?? '',
      paymentUrl: json['payment_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'payment_url': paymentUrl,
      };
}
