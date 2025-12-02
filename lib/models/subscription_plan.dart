// Subscription plan model and registry.

class SubscriptionPlan {
  final String id;
  final String name;
  final int? imageQuota; // null means unlimited
  final int? durationDays; // null means no expiry
  final int priceInINR; // 0 for free
  final bool adSupported;
  final String? description; // Plan description
  final double? price; // Price in USD for international payments
  final String statusCode; // F, FD, FW, FM, FY, G
  final String? googlePlayProductId; // Google Play product ID for in-app purchases

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.imageQuota,
    required this.durationDays,
    required this.priceInINR,
    required this.adSupported,
    required this.statusCode,
    this.description,
    this.price,
    this.googlePlayProductId,
  });

  String get priceLabel => priceInINR == 0 ? 'Free' : '₹$priceInINR';

  bool get isFree => priceInINR == 0;
  
  // Get price in USD (converts from INR if not set)
  double get priceUSD => price ?? (priceInINR / 83.0);
}

class PlansRegistry {
  // Assumptions: 1000 image plan valid 30 days, 25 image plan price assumed 99 INR (user did not specify), documented for adjustment.
  static const SubscriptionPlan free = SubscriptionPlan(
    id: 'free',
    name: 'Free (Ads)',
    description: 'Get started with basic editing features',
    imageQuota: 15, // starter quota
    durationDays: null,
    priceInINR: 0,
    price: 0.0,
    adSupported: true,
    statusCode: 'F',
    googlePlayProductId: null, // No product ID for free plan
  );
  
  static const SubscriptionPlan day25 = SubscriptionPlan(
    id: 'day25',
    name: '25 Images / 1 Day',
    description: 'Perfect for quick projects and trial',
    imageQuota: 25,
    durationDays: 1,
    priceInINR: 99,
    price: 1.19, // ~99 INR in USD
    adSupported: false,
    statusCode: 'FD',
    googlePlayProductId: 'pickoo_day25',
  );
  
  static const SubscriptionPlan week100 = SubscriptionPlan(
    id: 'week100',
    name: '100 Images / 1 Week',
    description: 'Ideal for weekly content creators',
    imageQuota: 100,
    durationDays: 7,
    priceInINR: 500,
    price: 6.02, // ~500 INR in USD
    adSupported: false,
    statusCode: 'FW',
    googlePlayProductId: 'pickoo_week100',
  );
  
  static const SubscriptionPlan month1000 = SubscriptionPlan(
    id: 'month1000',
    name: '1000 Images / 30 Days',
    description: 'Best value for professionals and power users',
    imageQuota: 1000,
    durationDays: 30,
    priceInINR: 999,
    price: 12.04, // ~999 INR in USD
    adSupported: false,
    statusCode: 'FM',
    googlePlayProductId: 'pickoo_month1000',
  );
  
  static const SubscriptionPlan yearUnlimited = SubscriptionPlan(
    id: 'year_unlimited',
    name: 'Unlimited / 1 Year',
    description: 'Ultimate plan for professionals',
    imageQuota: null, // Unlimited
    durationDays: 365,
    priceInINR: 8299,
    price: 99.99,
    adSupported: false,
    statusCode: 'FY',
    googlePlayProductId: 'pickoo_year_unlimited',
  );

  static const List<SubscriptionPlan> all = [free, day25, week100, month1000, yearUnlimited];

  static SubscriptionPlan byId(String id) => all.firstWhere((p) => p.id == id, orElse: () => free);
}
