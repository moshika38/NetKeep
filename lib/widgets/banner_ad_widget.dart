import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netkeep/services/ad_helper.dart';

/// Production-ready reusable Banner Ad Widget with automatic retry & lifecycle recovery.
///
/// Automatically loads the Banner Ad Unit ID from [AdHelper] (which reads from `.env`).
/// Handles loading state, exponential backoff retries on failure, lifecycle resume reloads,
/// and safe memory cleanup on widget disposal.
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsetsGeometry padding;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBannerAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isAdLoaded && !_isAdLoading) {
        debugPrint('BannerAdWidget: App resumed. Retrying banner ad load...');
        _loadBannerAd();
      }
    }
  }

  void _loadBannerAd() {
    if (_isAdLoading || (_isAdLoaded && _bannerAd != null)) {
      return;
    }

    final adUnitId = AdHelper.bannerAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('BannerAdWidget: Banner Ad Unit ID is empty.');
      return;
    }

    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoading = true;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAdWidget: BannerAd loaded successfully.');
          _isAdLoading = false;
          _retryAttempt = 0;
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAdWidget: BannerAd failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _isAdLoading = false;
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
          _scheduleRetry();
        },
      ),
    );

    _bannerAd!.load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    // Increasing delay: 5s, 10s, 20s, 40s, capped at 60s
    final delaySeconds = (5 * pow(2, min(_retryAttempt, 4))).toInt().clamp(5, 60);
    _retryAttempt++;

    debugPrint('BannerAdWidget: Scheduling banner ad retry in ${delaySeconds}s (Attempt $_retryAttempt)...');
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted && !_isAdLoaded && !_isAdLoading) {
        _loadBannerAd();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
