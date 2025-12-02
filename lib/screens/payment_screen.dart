import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/tool_provider.dart';
import '../models/subscription_plan.dart';
import '../services/in_app_purchase_service.dart';

/// Payment screen for handling subscription purchases
class PaymentScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late PageController _pageController;
  late int _currentPlanIndex;

  @override
  void initState() {
    super.initState();
    // Find initial plan index
    _currentPlanIndex = PlansRegistry.all.indexWhere((p) => p.id == widget.plan.id);
    if (_currentPlanIndex == -1) _currentPlanIndex = 1; // Default to first paid plan
    
    _pageController = PageController(
      initialPage: _currentPlanIndex,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    final productsState = ref.watch(productsProvider);

    // Listen for completed purchases
    ref.listen<PurchaseState>(purchaseProvider, (previous, next) {
      if (next.completedPurchase != null) {
        _handleCompletedPurchase(context, next.completedPurchase!);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(purchaseProvider.notifier).clearError();
      }
    });

    // Fetch products on first load
    if (!productsState.isLoading && productsState.products.isEmpty && productsState.error == null) {
      Future.microtask(() => ref.read(productsProvider.notifier).fetchProducts());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Web platform warning
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'In-app purchases are only available on mobile apps. Download our Android/iOS app to subscribe.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            // Title
            const Text(
              'Choose Your Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Swipe to explore different plans',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Scrollable plan carousel
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPlanIndex = index;
                  });
                },
                itemCount: PlansRegistry.all.length,
                itemBuilder: (context, index) {
                  final plan = PlansRegistry.all[index];
                  final isActive = index == _currentPlanIndex;
                  
                  return AnimatedScale(
                    scale: isActive ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          color: Colors.grey[900],
                          elevation: isActive ? 12 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isActive 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white12,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  plan.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plan.description ?? 'Premium subscription plan',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                
                                // Price from Google Play or fallback
                                Builder(
                                  builder: (context) {
                                    final product = ref.read(productsProvider.notifier).getProductForPlan(plan);
                                    final displayPrice = product?.price ?? plan.priceLabel;
                                    
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayPrice,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (plan.durationDays != null)
                                          Text(
                                            'per ${plan.durationDays} day${plan.durationDays! > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 10),
                                const Divider(color: Colors.white24, height: 1),
                                const SizedBox(height: 10),
                                
                                // Features
                                if (plan.imageQuota != null)
                                  _buildFeatureRow(
                                    Icons.image,
                                    '${plan.imageQuota} images',
                                  ),
                                if (plan.durationDays != null)
                                  _buildFeatureRow(
                                    Icons.calendar_today,
                                    '${plan.durationDays} days',
                                  ),
                                if (!plan.adSupported)
                                  _buildFeatureRow(
                                    Icons.block,
                                    'Ad-free',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                PlansRegistry.all.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPlanIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPlanIndex
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Payment method info
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Secure in-app payment powered by Google Play',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Credit/Debit Cards\n• Google Pay\n• Carrier Billing\n• Secure & Encrypted',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (purchaseState.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        purchaseState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Proceed to payment button
            ElevatedButton(
              onPressed: purchaseState.isPurchasing || productsState.isLoading
                  ? null
                  : () => _handlePayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: (purchaseState.isPurchasing || productsState.isLoading)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      kIsWeb ? 'View Payment Options' : 'Proceed to Payment',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Terms and security info
            Text(
              kIsWeb 
                ? 'Download our mobile app from Play Store or App Store to purchase subscriptions.'
                : 'By proceeding, you agree to our Terms of Service and Privacy Policy. Your payment is securely processed by Google Play.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context) async {
    final auth = ref.read(authProvider);
    
    if (!auth.isAuthenticated) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    final currentPlan = PlansRegistry.all[_currentPlanIndex];
    
    if (currentPlan.id == 'free') {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already on the free plan')),
      );
      return;
    }

    // Check if running on web
    if (kIsWeb) {
      if (!context.mounted) return;
      
      // Show dialog explaining web payment limitation
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueAccent),
              SizedBox(width: 12),
              Text('Payment on Web', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'In-app purchases are only available on Android/iOS apps.\n\n'
            'To purchase a subscription:\n'
            '1. Download the mobile app from Play Store or App Store\n'
            '2. Or contact support for alternative payment methods\n\n'
            'Would you like to continue using the free plan?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue Free', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );
      
      if (shouldContinue == true && context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Initiate Google Play Billing purchase (Android/iOS only)
    await ref.read(purchaseProvider.notifier).purchasePlan(currentPlan);
  }

  /// Handle completed purchase by verifying with backend
  Future<void> _handleCompletedPurchase(BuildContext context, dynamic purchaseDetails) async {
    try {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) return;

      // Send purchase details to backend for verification
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.verifyGooglePlayPurchase(
        userId: auth.userId!,
        purchaseToken: purchaseDetails.verificationData.serverVerificationData,
        productId: purchaseDetails.productID,
      );

      if (response['success'] == true) {
        // Clear the completed purchase
        ref.read(purchaseProvider.notifier).clearCompletedPurchase();
        
        // Update local subscription state (backend will track in MongoDB)
        // Find which plan was purchased
        final purchasedPlan = PlansRegistry.all.firstWhere(
          (p) => p.googlePlayProductId == purchaseDetails.productID,
          orElse: () => PlansRegistry.free,
        );
        
        if (purchasedPlan.id != 'free') {
          ref.read(subscriptionProvider.notifier).purchase(purchasedPlan);
        }
        
        if (!context.mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Purchase successful! Your subscription is now active.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to profile
        Navigator.of(context).pop();
      } else {
        throw Exception(response['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Clear the purchase
      ref.read(purchaseProvider.notifier).clearCompletedPurchase();
    }
  }
}
