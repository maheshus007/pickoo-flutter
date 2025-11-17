// Subscription plan model and registry.

class SubscriptionPlan {
  final String id;
  final String name;
  final int? imageQuota; // null means unlimited
  final int? durationDays; // null means no expiry
  final int priceInINR; // 0 for free
  final bool adSupported;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.imageQuota,
    required this.durationDays,
    required this.priceInINR,
    required this.adSupported,
  });

  String get priceLabel => priceInINR == 0 ? 'Free' : '₹$priceInINR';

  bool get isFree => priceInINR == 0;
}

class PlansRegistry {
  // Assumptions: 1000 image plan valid 30 days, 25 image plan price assumed 99 INR (user did not specify), documented for adjustment.
  static const SubscriptionPlan free = SubscriptionPlan(
    id: 'free',
    name: 'Free (Ads)',
    imageQuota: 15, // starter quota
    durationDays: null,
    priceInINR: 0,
    adSupported: true,
  );
  static const SubscriptionPlan day25 = SubscriptionPlan(
    id: 'day25',
    name: '25 Images / 1 Day',
    imageQuota: 25,
    durationDays: 1,
    priceInINR: 99, // assumption
    adSupported: false,
  );
  static const SubscriptionPlan week100 = SubscriptionPlan(
    id: 'week100',
    name: '100 Images / 1 Week',
    imageQuota: 100,
    durationDays: 7,
    priceInINR: 500,
    adSupported: false,
  );
  static const SubscriptionPlan month1000 = SubscriptionPlan(
    id: 'month1000',
    name: '1000 Images / 30 Days',
    imageQuota: 1000,
    durationDays: 30, // assumption for batch plan
    priceInINR: 999,
    adSupported: false,
  );

  static const List<SubscriptionPlan> all = [free, day25, week100, month1000];

  static SubscriptionPlan byId(String id) => all.firstWhere((p) => p.id == id);
}
