import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plan.dart';

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
    // Default free plan.
    return const SubscriptionState(plan: PlansRegistry.free);
  }

  void purchase(SubscriptionPlan plan) {
    state = SubscriptionState(plan: plan, purchasedAt: DateTime.now());
  }

  void recordUsage() {
    if (state.isExpired) {
      state = state.copyWith(error: 'Plan expired');
      return;
    }
    if (state.quotaExceeded) {
      state = state.copyWith(error: 'Image quota reached');
      return;
    }
    state = state.copyWith(usedImages: state.usedImages + 1, error: null);
  }

  void resetError() => state = state.copyWith(error: null);
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(() => SubscriptionNotifier());
