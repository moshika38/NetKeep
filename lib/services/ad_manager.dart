import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netkeep/services/ad_helper.dart';

/// Service class to manage loading and presenting Interstitial Ads across the application.
class AdManager {
  /// Singleton instance for convenient global access.
  static final AdManager instance = AdManager();

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  /// Returns true if an Interstitial Ad is loaded and ready to show.
  bool get isInterstitialAdReady => _interstitialAd != null;

  /// Loads an Interstitial Ad asynchronously using the ID configured via [AdHelper].
  void loadInterstitialAd({
    VoidCallback? onAdLoaded,
    Function(LoadAdError error)? onAdFailedToLoad,
  }) {
    if (_isAdLoading || _interstitialAd != null) {
      return;
    }

    final String adUnitId = AdHelper.interstitialAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('AdManager: Interstitial Ad Unit ID is empty.');
      return;
    }

    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          debugPrint('AdManager: InterstitialAd loaded successfully.');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isAdLoading = false;
          debugPrint('AdManager: InterstitialAd failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  /// Triggers an Interstitial Ad if available, auto-preloading the next ad upon completion.
  ///
  /// Executes [onComplete] immediately if the ad is not ready, ensuring user actions
  /// proceed without freezing or delay.
  void showAdIfReady({VoidCallback? onComplete}) {
    if (!isInterstitialAdReady) {
      debugPrint('AdManager: InterstitialAd not ready. Proceeding with flow & preloading.');
      onComplete?.call();
      loadInterstitialAd();
      return;
    }

    showInterstitialAd(
      onAdDismissed: () {
        onComplete?.call();
        loadInterstitialAd();
      },
      onAdFailed: () {
        onComplete?.call();
        loadInterstitialAd();
      },
    );
  }

  /// Shows the loaded Interstitial Ad if available.
  ///
  /// Automatically disposes the ad after it is dismissed or fails to show,
  /// executing optional callbacks [onAdDismissed] or [onAdFailed].
  void showInterstitialAd({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailed,
  }) {
    if (_interstitialAd == null) {
      debugPrint('AdManager: Cannot show InterstitialAd - ad is not ready.');
      onAdFailed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdManager: InterstitialAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdManager: InterstitialAd dismissed.');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdManager: InterstitialAd failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        onAdFailed?.call();
      },
    );

    _interstitialAd!.show();
  }

  /// Disposes of active resources.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
