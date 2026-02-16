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

class TopUpResponse {
  final String paymentUrl;
  final String? paymentId;

  TopUpResponse({
    this.paymentUrl = '',
    this.paymentId,
  });

  factory TopUpResponse.fromJson(Map<String, dynamic> json) {
    return TopUpResponse(
      paymentUrl: json['payment_url'] as String? ?? '',
      paymentId: json['payment_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'payment_url': paymentUrl,
        'payment_id': paymentId,
      };
}
