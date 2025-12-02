import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/in_app_purchase_service.dart';
import '../models/subscription_plan.dart';

/// Provider for InAppPurchaseService
final inAppPurchaseServiceProvider = Provider<InAppPurchaseService>((ref) {
  final service = InAppPurchaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State for available products
class ProductsState {
  final Map<String, ProductDetails> products;
  final bool isLoading;
  final String? error;

  const ProductsState({
    this.products = const {},
    this.isLoading = false,
    this.error,
  });

  ProductsState copyWith({
    Map<String, ProductDetails>? products,
    bool? isLoading,
    String? error,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing product fetching
class ProductsNotifier extends StateNotifier<ProductsState> {
  final InAppPurchaseService _purchaseService;

  ProductsNotifier(this._purchaseService) : super(const ProductsState());

  /// Fetch all available products from the store
  Future<void> fetchProducts() async {
    if (!InAppPurchaseService.isPlatformSupported) {
      state = state.copyWith(
        error: 'In-app purchases not supported on this platform',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get all product IDs (excluding free plan and filtering out nulls)
      final productIds = {
        PlansRegistry.day25.googlePlayProductId,
        PlansRegistry.week100.googlePlayProductId,
        PlansRegistry.month1000.googlePlayProductId,
        PlansRegistry.yearUnlimited.googlePlayProductId,
      }.whereType<String>().toSet(); // Filter out null values and convert to Set<String>

      final products = await _purchaseService.fetchProducts(productIds);
      
      state = state.copyWith(
        products: products,
        isLoading: false,
        error: products.isEmpty ? 'No products available' : null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Get product details for a specific subscription plan
  ProductDetails? getProductForPlan(SubscriptionPlan plan) {
    if (plan.id == 'free') return null;
    return state.products[plan.googlePlayProductId];
  }
}

/// Provider for products state
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final service = ref.watch(inAppPurchaseServiceProvider);
  return ProductsNotifier(service);
});

/// State for purchase flow
class PurchaseState {
  final bool isPurchasing;
  final String? purchasingProductId;
  final String? error;
  final PurchaseDetails? completedPurchase;

  const PurchaseState({
    this.isPurchasing = false,
    this.purchasingProductId,
    this.error,
    this.completedPurchase,
  });

  PurchaseState copyWith({
    bool? isPurchasing,
    String? purchasingProductId,
    String? error,
    PurchaseDetails? completedPurchase,
  }) {
    return PurchaseState(
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchasingProductId: purchasingProductId ?? this.purchasingProductId,
      error: error,
      completedPurchase: completedPurchase ?? this.completedPurchase,
    );
  }
}

/// Notifier for managing purchase flow
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final InAppPurchaseService _purchaseService;

  PurchaseNotifier(this._purchaseService) : super(const PurchaseState()) {
    // Set up callbacks
    _purchaseService.onPurchaseSuccess = _handlePurchaseSuccess;
    _purchaseService.onPurchaseError = _handlePurchaseError;
  }

  void _handlePurchaseSuccess(PurchaseDetails details) {
    state = state.copyWith(
      isPurchasing: false,
      purchasingProductId: null,
      completedPurchase: details,
      error: null,
    );
  }

  void _handlePurchaseError(String error) {
    state = state.copyWith(
      isPurchasing: false,
      purchasingProductId: null,
      error: error,
    );
  }

  /// Initiate purchase for a subscription plan
  Future<void> purchasePlan(SubscriptionPlan plan) async {
    if (!InAppPurchaseService.isPlatformSupported) {
      state = state.copyWith(
        error: 'In-app purchases not supported on this platform',
      );
      return;
    }

    if (plan.id == 'free') {
      state = state.copyWith(
        error: 'Cannot purchase free plan',
      );
      return;
    }

    if (plan.googlePlayProductId == null || plan.googlePlayProductId!.isEmpty) {
      state = state.copyWith(
        error: 'Invalid product configuration. Please contact support.',
      );
      return;
    }

    state = state.copyWith(
      isPurchasing: true,
      purchasingProductId: plan.googlePlayProductId,
      error: null,
    );

    final success = await _purchaseService.purchaseSubscription(plan.googlePlayProductId!);
    
    if (!success) {
      state = state.copyWith(
        isPurchasing: false,
        purchasingProductId: null,
        error: 'Failed to initiate purchase',
      );
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!InAppPurchaseService.isPlatformSupported) {
      state = state.copyWith(
        error: 'In-app purchases not supported on this platform',
      );
      return;
    }

    state = state.copyWith(
      isPurchasing: true,
      error: null,
    );

    await _purchaseService.restorePurchases();

    state = state.copyWith(
      isPurchasing: false,
    );
  }

  /// Clear completed purchase (after processing)
  void clearCompletedPurchase() {
    state = state.copyWith(
      completedPurchase: null,
      error: null,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for purchase state
final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final service = ref.watch(inAppPurchaseServiceProvider);
  return PurchaseNotifier(service);
});
