import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Ad service provider
final adServiceProvider = Provider<AdService>((ref) {
  final adService = AdService();
  // Preload first interstitial ad
  adService.loadInterstitialAd();
  return adService;
});

/// Banner ad state
class BannerAdState {
  final BannerAd? ad;
  final bool isLoaded;
  final String? error;

  const BannerAdState({
    this.ad,
    this.isLoaded = false,
    this.error,
  });

  BannerAdState copyWith({
    BannerAd? ad,
    bool? isLoaded,
    String? error,
  }) {
    return BannerAdState(
      ad: ad ?? this.ad,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
    );
  }
}

/// Banner ad state notifier
class BannerAdNotifier extends StateNotifier<BannerAdState> {
  final AdService _adService;

  BannerAdNotifier(this._adService) : super(const BannerAdState());

  /// Load a banner ad
  void loadBannerAd() {
    _adService.createBannerAd(
      onAdLoaded: (ad) {
        state = state.copyWith(
          ad: ad as BannerAd,
          isLoaded: true,
          error: null,
        );
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        state = state.copyWith(
          ad: null,
          isLoaded: false,
          error: error.message,
        );
      },
    );
  }

  /// Dispose the banner ad
  void disposeBannerAd() {
    _adService.disposeBannerAd();
    state = const BannerAdState();
  }

  @override
  void dispose() {
    _adService.disposeBannerAd();
    super.dispose();
  }
}

/// Banner ad provider
final bannerAdProvider = StateNotifierProvider<BannerAdNotifier, BannerAdState>((ref) {
  final adService = ref.watch(adServiceProvider);
  return BannerAdNotifier(adService);
});
