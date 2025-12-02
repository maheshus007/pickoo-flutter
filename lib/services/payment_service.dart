import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';

/// Service for handling payment operations with backend API and UPI launcher.
class PaymentService {
  final String baseUrl;
  final Dio _dio;

  PaymentService(this.baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  // -------- Backend payment APIs (Stripe/Checkout) --------
  Future<CurrencyInfo> detectCurrency() async {
    try {
      final response = await _dio.get('/payment/detect-currency');
      return CurrencyInfo.fromJson(response.data);
    } catch (e) {
      return CurrencyInfo(countryCode: 'US', currency: 'usd', symbol: '4');
    }
  }

  Future<PaymentCheckoutResponse> createCheckoutSession({
    required String userId,
    required String planId,
    String? countryCode,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      String country = countryCode ?? 'US';
      if (countryCode == null) {
        try {
          final currencyInfo = await detectCurrency();
          country = currencyInfo.countryCode;
        } catch (_) {}
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

  Future<List<PaymentRecord>> getPaymentHistory(
    String userId, {
    String? authToken,
  }) async {
    try {
      final options = Options(
        headers: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
      );

      final response = await _dio.get(
        '/payment/history/$userId',
        options: options,
      );

      final List<dynamic> paymentsJson = response.data['payments'];
      return paymentsJson.map((json) => PaymentRecord.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
          'Failed to get payment history: ${e.response?.data['detail'] ?? e.message}');
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

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
    final isZeroDecimal = ['jpy', 'krw', 'idr'].contains(currencyInfo.currency.toLowerCase());
    return isZeroDecimal
        ? '${currencyInfo.symbol}${converted.toStringAsFixed(0)}'
        : '${currencyInfo.symbol}${converted.toStringAsFixed(2)}';
  }

  Future<bool> verifyPaymentSuccess(String sessionId) async {
    try {
      final response = await _dio.get('/payment/session/$sessionId');
      return response.data['status'] == 'completed';
    } catch (e) {
      return false;
    }
  }

  // -------- UPI (Google Pay) launcher --------
  static Future<void> startGPayUpi({
    required BuildContext context,
    required String pa,
    required String pn,
    required String am,
    required String tn,
    required String tid,
    String? currency,
  }) async {
    final params = {
      'pa': pa,
      'pn': pn,
      'am': am,
      'tn': tn,
      'tid': tid,
      'cu': currency ?? 'INR',
      'url': 'https://codesurge.ai/pickoo',
    };
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final genericUpi = Uri.parse('upi://pay?$query');
    final gpayLegacy1 = Uri.parse('tez://upi/pay?$query');
    final gpayLegacy2 = Uri.parse('googlepay://upi/pay?$query');
    final gpayPlayStore = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.paisa.user');

    if (kIsWeb) {
      _showSnack(context, 'Payments are not supported on web.');
      return;
    }
    if (await _tryLaunchUri(genericUpi)) return;
    if (await _tryLaunchUri(gpayLegacy1)) return;
    if (await _tryLaunchUri(gpayLegacy2)) return;

    final openedStore = await launchUrl(gpayPlayStore, mode: LaunchMode.externalApplication);
    if (!openedStore) {
      _showSnack(context, 'No UPI app found. Please install Google Pay.');
    }
  }

  static Future<bool> _tryLaunchUri(Uri uri) async {
    try {
      final can = await canLaunchUrl(uri);
      if (!can) return false;
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok;
    } catch (_) {
      return false;
    }
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
