import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper class to manage Google AdMob App and Unit IDs safely via [dotenv].
///
/// Automatically uses official Google Test Ad Unit IDs in debug mode ([kDebugMode])
/// to guarantee 100% ad fill rate during testing and development, avoiding AdMob
/// "No fill" (code 3) errors. Uses production IDs from `.env` in release builds.
class AdHelper {
  // Official Google AdMob Test Unit IDs
  static const String _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIdIos = 'ca-app-pub-3940256099942544/4411468910';

  static const String _testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String _testAppIdIos = 'ca-app-pub-3940256099942544~1458002511';

  /// Returns the AdMob Application ID. Uses Google Test App ID in debug mode,
  /// and the configured ID from `.env` in release mode.
  static String get appId {
    if (kDebugMode) {
      if (kIsWeb) return '';
      return Platform.isIOS ? _testAppIdIos : _testAppIdAndroid;
    }
    final String? id = dotenv.env['ADMOB_APP_ID'];
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (kIsWeb) return '';
    return Platform.isIOS ? _testAppIdIos : _testAppIdAndroid;
  }

  /// Returns the Banner Ad Unit ID. Uses Google Test Banner ID in debug mode,
  /// and the configured ID from `.env` in release mode.
  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (kIsWeb) return '';
      return Platform.isIOS ? _testBannerIdIos : _testBannerIdAndroid;
    }
    final String? id = dotenv.env['ADMOB_BANNER_ID'];
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (kIsWeb) return '';
    return Platform.isIOS ? _testBannerIdIos : _testBannerIdAndroid;
  }

  /// Returns the Interstitial Ad Unit ID. Uses Google Test Interstitial ID in debug mode,
  /// and the configured ID from `.env` in release mode.
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (kIsWeb) return '';
      return Platform.isIOS ? _testInterstitialIdIos : _testInterstitialIdAndroid;
    }
    final String? id = dotenv.env['ADMOB_INTERSTITIAL_ID'];
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (kIsWeb) return '';
    return Platform.isIOS ? _testInterstitialIdIos : _testInterstitialIdAndroid;
  }
}

