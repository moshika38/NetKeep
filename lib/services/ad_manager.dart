import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netkeep/services/ad_helper.dart';

/// Service class to manage loading and presenting Interstitial Ads across the application.
class AdManager {
  /// Singleton instance for convenient global access.
  static final AdManager instance = AdManager();

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _isAdShowing = false;
  Timer? _retryTimer;

  /// Returns true if an Interstitial Ad is loaded and ready to show.
  bool get isInterstitialAdReady => _interstitialAd != null;

  /// Returns true if an ad is currently being loaded.
  bool get isAdLoading => _isAdLoading;

  /// Returns true if an ad is currently showing on screen.
  bool get isAdShowing => _isAdShowing;

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

    _retryTimer?.cancel();
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
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (_interstitialAd == null && !_isAdLoading) {
        debugPrint('AdManager: Retrying InterstitialAd load...');
        loadInterstitialAd();
      }
    });
  }

  /// Triggers an Interstitial Ad if available, auto-preloading the next ad upon completion.
  ///
  /// If an ad is currently loading, waits up to [timeout] before proceeding.
  /// Executes [onComplete] immediately if the ad is not ready, ensuring user actions
  /// proceed without freezing or delay.
  Future<void> showAdIfReady({
    VoidCallback? onComplete,
    Duration timeout = const Duration(milliseconds: 3000),
  }) async {
    bool hasCompleted = false;
    void safeOnComplete() {
      if (!hasCompleted) {
        hasCompleted = true;
        onComplete?.call();
      }
    }

    if (_isAdShowing) {
      debugPrint('AdManager: Ad is already showing.');
      safeOnComplete();
      return;
    }

    // If ad is not loaded and not loading, initiate load now.
    if (!_isAdLoading && _interstitialAd == null) {
      loadInterstitialAd();
    }

    // If ad is loading, poll briefly up to [timeout] for it to finish loading.
    if (_isAdLoading && _interstitialAd == null) {
      final Stopwatch sw = Stopwatch()..start();
      while (_isAdLoading && _interstitialAd == null && sw.elapsed < timeout) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!isInterstitialAdReady || _isAdShowing) {
      debugPrint('AdManager: InterstitialAd not ready after wait. Proceeding with flow & preloading.');
      safeOnComplete();
      loadInterstitialAd();
      return;
    }

    showInterstitialAd(
      onAdDismissed: () {
        safeOnComplete();
        loadInterstitialAd();
      },
      onAdFailed: () {
        safeOnComplete();
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
    if (_interstitialAd == null || _isAdShowing) {
      debugPrint('AdManager: Cannot show InterstitialAd - ad is not ready or already showing.');
      onAdFailed?.call();
      return;
    }

    _isAdShowing = true;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdManager: InterstitialAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdManager: InterstitialAd dismissed.');
        _isAdShowing = false;
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdManager: InterstitialAd failed to show: $error');
        _isAdShowing = false;
        ad.dispose();
        _interstitialAd = null;
        onAdFailed?.call();
      },
    );

    _interstitialAd!.show();
  }

  /// Disposes of active resources.
  void dispose() {
    _retryTimer?.cancel();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoading = false;
    _isAdShowing = false;
  }
}

