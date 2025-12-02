import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription_plan.dart';

/// Service for handling Google Play Billing and App Store in-app purchases
/// Manages product fetching, purchase flow, and purchase verification
class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  
  /// Check if in-app purchases are supported on this platform
  static bool get isPlatformSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  /// Callback when purchase is completed successfully
  Function(PurchaseDetails)? onPurchaseSuccess;
  
  /// Callback when purchase fails or is cancelled
  Function(String error)? onPurchaseError;
  
  /// Initialize the in-app purchase service and listen for purchase updates
  Future<void> initialize() async {
    if (!isPlatformSupported) {
      if (kDebugMode) {
        print('In-app purchases not supported on this platform (web/desktop)');
      }
      return;
    }
    
    // Check if the store is available
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (kDebugMode) {
        print('In-app purchase store is not available');
      }
      return;
    }
    
    // Platform-specific configuration
    // Note: In newer versions of in_app_purchase_android, pending purchases are automatically enabled
    if (Platform.isAndroid) {
      // Android-specific setup can be added here if needed in future
    }
    
    // Listen for purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () {
        _purchaseSubscription.cancel();
      },
      onError: (error) {
        if (kDebugMode) {
          print('Purchase stream error: $error');
        }
        onPurchaseError?.call(error.toString());
      },
    );
  }
  
  /// Handle purchase updates from the store
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        if (kDebugMode) {
          print('Purchase pending: ${purchaseDetails.productID}');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        if (kDebugMode) {
          print('Purchase error: ${purchaseDetails.error}');
        }
        onPurchaseError?.call(purchaseDetails.error?.message ?? 'Purchase failed');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase with backend before delivering content
        if (kDebugMode) {
          print('Purchase successful: ${purchaseDetails.productID}');
        }
        onPurchaseSuccess?.call(purchaseDetails);
      }
      
      // Complete the purchase (mark as consumed/acknowledged)
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// Fetch available products from the store
  /// Returns map of productId -> ProductDetails
  Future<Map<String, ProductDetails>> fetchProducts(Set<String> productIds) async {
    if (!isPlatformSupported) {
      if (kDebugMode) {
        print('Platform does not support in-app purchases');
      }
      return {};
    }
    
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        if (kDebugMode) {
          print('Error fetching products: ${response.error}');
        }
        return {};
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print('Products not found: ${response.notFoundIDs}');
        }
      }
      
      // Convert list to map for easy lookup
      final Map<String, ProductDetails> productMap = {};
      for (final product in response.productDetails) {
        productMap[product.id] = product;
      }
      
      return productMap;
    } catch (e) {
      if (kDebugMode) {
        print('Exception fetching products: $e');
      }
      return {};
    }
  }
  
  /// Initiate a purchase for a subscription plan
  Future<bool> purchaseSubscription(String productId) async {
    if (!isPlatformSupported) {
      if (kDebugMode) {
        print('Platform does not support in-app purchases');
      }
      return false;
    }
    
    try {
      // Fetch the product details
      final productIds = {productId};
      final products = await fetchProducts(productIds);
      
      if (!products.containsKey(productId)) {
        if (kDebugMode) {
          print('Product not found: $productId');
        }
        onPurchaseError?.call('Product not found');
        return false;
      }
      
      final ProductDetails productDetails = products[productId]!;
      
      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      
      // Initiate purchase
      // For subscriptions, use buyNonConsumable (one-time purchase that doesn't get consumed)
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Exception during purchase: $e');
      }
      onPurchaseError?.call(e.toString());
      return false;
    }
  }
  
  /// Restore previous purchases (useful for users who reinstalled the app)
  Future<void> restorePurchases() async {
    if (!isPlatformSupported) {
      return;
    }
    
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) {
        print('Exception restoring purchases: $e');
      }
      onPurchaseError?.call('Failed to restore purchases');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _purchaseSubscription.cancel();
  }
}

/// Extension to get Google Play product ID for a subscription plan
extension SubscriptionPlanProductId on SubscriptionPlan {
  /// Get the Google Play Console product ID for this plan
  /// These IDs must match what you configure in Google Play Console
  String get googlePlayProductId {
    switch (id) {
      case 'day25':
        return 'neuralens_day_25';
      case 'week100':
        return 'neuralens_week_100';
      case 'month1000':
        return 'neuralens_month_1000';
      case 'year_unlimited':
        return 'neuralens_year_unlimited';
      default:
        return 'neuralens_free'; // Free plan has no product
    }
  }
}
