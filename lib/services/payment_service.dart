import 'package:dio/dio.dart';
import '../models/payment.dart';

/// Service for handling payment operations with backend API.
class PaymentService {
  final String baseUrl;
  final Dio _dio;

  PaymentService(this.baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Detect user's currency based on their location (IP-based).
  /// Returns currency information for displaying prices.
  Future<CurrencyInfo> detectCurrency() async {
    try {
      final response = await _dio.get('/payment/detect-currency');
      return CurrencyInfo.fromJson(response.data);
    } catch (e) {
      // Fallback to USD if detection fails
      return CurrencyInfo(
        countryCode: 'US',
        currency: 'usd',
        symbol: '\$',
      );
    }
  }

  /// Create a Stripe Checkout session for subscription purchase.
  /// Returns checkout URL to redirect user for payment.
  Future<PaymentCheckoutResponse> createCheckoutSession({
    required String userId,
    required String planId,
    String? countryCode,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      // Auto-detect currency if not provided
      String country = countryCode ?? 'US';
      if (countryCode == null) {
        try {
          final currencyInfo = await detectCurrency();
          country = currencyInfo.countryCode;
        } catch (_) {
          // Use default if detection fails
        }
      }

      final request = PaymentCheckoutRequest(
        userId: userId,
        planId: planId,
        countryCode: country,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final response = await _dio.post(
        '/payment/create-checkout',
        data: request.toJson(),
      );

      return PaymentCheckoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          'Failed to create checkout session: ${e.response?.data['detail'] ?? e.message}');
    } catch (e) {
      throw Exception('Failed to create checkout session: $e');
    }
  }

  /// Get payment history for a user.
  /// Requires authentication token.
  Future<List<PaymentRecord>> getPaymentHistory(
    String userId, {
    String? authToken,
  }) async {
    try {
      final options = Options(
        headers: authToken != null
            ? {'Authorization': 'Bearer $authToken'}
            : null,
      );

      final response = await _dio.get(
        '/payment/history/$userId',
        options: options,
      );

      final List<dynamic> paymentsJson = response.data['payments'];
      return paymentsJson
          .map((json) => PaymentRecord.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          'Failed to get payment history: ${e.response?.data['detail'] ?? e.message}');
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  /// Format price for display in user's currency.
  /// Takes base USD price and converts to local currency with symbol.
  String formatPrice(double basePriceUsd, CurrencyInfo currencyInfo) {
    final conversionRates = {
      'usd': 1.0,
      'eur': 0.92,
      'gbp': 0.79,
      'cad': 1.36,
      'aud': 1.52,
      'inr': 83.0,
      'jpy': 149.0,
      'cny': 7.24,
      'sgd': 1.34,
      'hkd': 7.83,
      'nzd': 1.65,
      'chf': 0.88,
      'sek': 10.45,
      'nok': 10.75,
      'dkk': 6.88,
      'mxn': 17.0,
      'brl': 4.97,
      'zar': 18.5,
      'aed': 3.67,
      'sar': 3.75,
      'krw': 1315.0,
      'thb': 35.5,
      'myr': 4.68,
      'php': 56.0,
      'idr': 15600.0,
    };

    final rate = conversionRates[currencyInfo.currency.toLowerCase()] ?? 1.0;
    final converted = basePriceUsd * rate;

    // Zero-decimal currencies (no cents)
    final isZeroDecimal = ['jpy', 'krw', 'idr']
        .contains(currencyInfo.currency.toLowerCase());

    if (isZeroDecimal) {
      return '${currencyInfo.symbol}${converted.toStringAsFixed(0)}';
    } else {
      return '${currencyInfo.symbol}${converted.toStringAsFixed(2)}';
    }
  }

  /// Check if a payment was successful by session ID.
  /// Used after returning from payment flow.
  Future<bool> verifyPaymentSuccess(String sessionId) async {
    try {
      // This would typically call a backend endpoint to verify
      // For now, we'll implement basic verification
      final response = await _dio.get('/payment/session/$sessionId');
      return response.data['status'] == 'completed';
    } catch (e) {
      return false;
    }
  }
}
