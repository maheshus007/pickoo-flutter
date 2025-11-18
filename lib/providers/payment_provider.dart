import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(AppConfig.backendUrl);
});

/// Currency detection provider
final currencyProvider = FutureProvider<CurrencyInfo>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.detectCurrency();
});

/// Payment history provider
final paymentHistoryProvider = FutureProvider.family<List<PaymentRecord>, String>(
  (ref, userId) async {
    final paymentService = ref.watch(paymentServiceProvider);
    // TODO: Get auth token from auth provider
    return await paymentService.getPaymentHistory(userId);
  },
);

/// Payment state for checkout flow
class PaymentState {
  final bool isProcessing;
  final String? checkoutUrl;
  final String? error;
  final PaymentCheckoutResponse? lastCheckout;

  const PaymentState({
    this.isProcessing = false,
    this.checkoutUrl,
    this.error,
    this.lastCheckout,
  });

  PaymentState copyWith({
    bool? isProcessing,
    String? checkoutUrl,
    String? error,
    PaymentCheckoutResponse? lastCheckout,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      error: error,
      lastCheckout: lastCheckout ?? this.lastCheckout,
    );
  }
}

/// Payment state notifier
class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();

  /// Initialize checkout session for a subscription plan
  Future<void> createCheckout({
    required String userId,
    required String planId,
    String? countryCode,
    String? successUrl,
    String? cancelUrl,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      
      final checkout = await paymentService.createCheckoutSession(
        userId: userId,
        planId: planId,
        countryCode: countryCode,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      state = state.copyWith(
        isProcessing: false,
        checkoutUrl: checkout.checkoutUrl,
        lastCheckout: checkout,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset payment state
  void reset() {
    state = const PaymentState();
  }
}

/// Payment state provider
final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});
