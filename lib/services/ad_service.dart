import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/subscription_plan.dart';

/// Service for managing Google Mobile Ads
/// Shows interstitial ads before photo upload and banner ads after processing
/// Only displays ads for free tier users
class AdService {
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isInterstitialAdReady = false;
  
  /// Check if ads are supported on current platform (only Android/iOS)
  static bool get isPlatformSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  // Test Ad Unit IDs (replace with real IDs in production)
  // Get your Ad Unit IDs from: https://apps.admob.com
  static String get _testInterstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Android test ID
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS test ID
  
  static String get _testBannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android test ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS test ID
  
  // TODO: Replace with production Ad Unit IDs
  // static const String _productionInterstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
  // static const String _productionBannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
  
  /// Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    if (!isPlatformSupported) {
      if (kDebugMode) {
        print('Google Mobile Ads not supported on this platform (web/desktop)');
      }
      return;
    }
    await MobileAds.instance.initialize();
  }
  
  /// Check if user should see ads (free tier only)
  bool shouldShowAds(SubscriptionPlan plan) {
    return isPlatformSupported && plan.adSupported;
  }
  
  /// Load an interstitial ad (shown before photo upload)
  Future<void> loadInterstitialAd() async {
    if (!isPlatformSupported) return;
    
    await InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          // Set up full screen content callback
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Preload next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }
  
  /// Show the interstitial ad if ready
  /// Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
      return true;
    }
    return false;
  }
  
  /// Create a banner ad (shown after photo processing)
  BannerAd? createBannerAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) {
    if (!isPlatformSupported) return null;
    
    _bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) {},
        onAdClosed: (ad) {},
      ),
    );
    
    _bannerAd!.load();
    return _bannerAd;
  }
  
  /// Dispose of the banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
  
  /// Dispose of the interstitial ad
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
  
  /// Dispose all ads
  void dispose() {
    disposeInterstitialAd();
    disposeBannerAd();
  }
}
