import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plan.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'tool_provider.dart';

class SubscriptionState {
  final SubscriptionPlan plan;
  final DateTime? purchasedAt;
  final int usedImages;
  final String? error;

  const SubscriptionState({
    required this.plan,
    this.purchasedAt,
    this.usedImages = 0,
    this.error,
  });

  bool get isExpired {
    if (plan.durationDays == null || purchasedAt == null) return false;
    final expires = purchasedAt!.add(Duration(days: plan.durationDays!));
    return DateTime.now().isAfter(expires);
  }

  int? get remainingImages => plan.imageQuota == null ? null : (plan.imageQuota! - usedImages).clamp(0, plan.imageQuota!);

  bool get quotaExceeded => plan.imageQuota != null && usedImages >= plan.imageQuota!;

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    DateTime? purchasedAt,
    int? usedImages,
    String? error,
  }) => SubscriptionState(
        plan: plan ?? this.plan,
        purchasedAt: purchasedAt ?? this.purchasedAt,
        usedImages: usedImages ?? this.usedImages,
        error: error,
      );
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    // Load subscription status from backend
    _loadSubscriptionStatus();
    // Default free plan while loading
    return const SubscriptionState(plan: PlansRegistry.free);
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated && auth.userId != null) {
        final api = ref.read(apiServiceProvider);
        final status = await api.getSubscriptionStatus(auth.userId!);
        
        if (status != null) {
          // Parse the backend response
          final planId = status['plan_id'] as String? ?? 'free';
          final usedImages = status['used_images'] as int? ?? 0;
          final purchasedAtStr = status['purchased_at'] as String?;
          
          final plan = PlansRegistry.byId(planId);
          final purchasedAt = purchasedAtStr != null 
              ? DateTime.tryParse(purchasedAtStr) 
              : null;
          
          state = SubscriptionState(
            plan: plan,
            purchasedAt: purchasedAt,
            usedImages: usedImages,
          );
          
          print('[SubscriptionProvider] Loaded status: plan=$planId, used=$usedImages');
        }
      }
    } catch (e) {
      print('[SubscriptionProvider] Failed to load subscription status: $e');
    }
  }

  void purchase(SubscriptionPlan plan) {
    state = SubscriptionState(plan: plan, purchasedAt: DateTime.now());
  }

  Future<void> recordUsage() async {
    if (state.isExpired) {
      state = state.copyWith(error: 'Plan expired');
      return;
    }
    if (state.quotaExceeded) {
      state = state.copyWith(error: 'Image quota reached');
      return;
    }
    
    // Update local state
    state = state.copyWith(usedImages: state.usedImages + 1, error: null);
    
    // Record usage in backend
    try {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated && auth.userId != null) {
        final api = ref.read(apiServiceProvider);
        await api.recordUsage(auth.userId!);
      }
    } catch (e) {
      // Log but don't block user if backend update fails
      print('[SubscriptionProvider] Failed to record usage in backend: $e');
    }
  }

  void resetError() => state = state.copyWith(error: null);
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(() => SubscriptionNotifier());
