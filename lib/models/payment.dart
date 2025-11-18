/// Payment-related models for Pickoo AI.

class PaymentCheckoutRequest {
  final String userId;
  final String planId;
  final String countryCode;
  final String? successUrl;
  final String? cancelUrl;

  PaymentCheckoutRequest({
    required this.userId,
    required this.planId,
    this.countryCode = 'US',
    this.successUrl,
    this.cancelUrl,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'plan_id': planId,
        'country_code': countryCode,
        if (successUrl != null) 'success_url': successUrl,
        if (cancelUrl != null) 'cancel_url': cancelUrl,
      };
}

class PaymentCheckoutResponse {
  final String sessionId;
  final String checkoutUrl;
  final int amount;
  final String currency;

  PaymentCheckoutResponse({
    required this.sessionId,
    required this.checkoutUrl,
    required this.amount,
    required this.currency,
  });

  factory PaymentCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return PaymentCheckoutResponse(
      sessionId: json['session_id'] as String,
      checkoutUrl: json['checkout_url'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
    );
  }
}

class PaymentRecord {
  final String userId;
  final String sessionId;
  final String planId;
  final String planName;
  final int amount;
  final String currency;
  final double basePriceUsd;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  PaymentRecord({
    required this.userId,
    required this.sessionId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.basePriceUsd,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String,
      planId: json['plan_id'] as String,
      planName: json['plan_name'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      basePriceUsd: (json['base_price_usd'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  String get displayAmount {
    // Format based on currency
    final isZeroDecimal = ['jpy', 'krw', 'idr'].contains(currency.toLowerCase());
    if (isZeroDecimal) {
      return '${_getCurrencySymbol()} ${amount.toString()}';
    } else {
      final displayValue = amount / 100.0;
      return '${_getCurrencySymbol()} ${displayValue.toStringAsFixed(2)}';
    }
  }

  String _getCurrencySymbol() {
    const symbols = {
      'usd': '\$',
      'eur': '€',
      'gbp': '£',
      'cad': 'CA\$',
      'aud': 'A\$',
      'inr': '₹',
      'jpy': '¥',
      'cny': '¥',
      'sgd': 'S\$',
      'hkd': 'HK\$',
      'nzd': 'NZ\$',
      'chf': 'CHF',
      'sek': 'kr',
      'nok': 'kr',
      'dkk': 'kr',
      'mxn': 'MX\$',
      'brl': 'R\$',
      'zar': 'R',
      'aed': 'AED',
      'sar': 'SAR',
      'krw': '₩',
      'thb': '฿',
      'myr': 'RM',
      'php': '₱',
      'idr': 'Rp',
    };
    return symbols[currency.toLowerCase()] ?? '\$';
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }
}

class CurrencyInfo {
  final String countryCode;
  final String currency;
  final String symbol;

  CurrencyInfo({
    required this.countryCode,
    required this.currency,
    required this.symbol,
  });

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
      countryCode: json['country_code'] as String,
      currency: json['currency'] as String,
      symbol: json['symbol'] as String,
    );
  }
}
