import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper class to manage Google AdMob App and Unit IDs safely via [dotenv].
///
/// Provides fallback Google Test Ad Unit IDs when keys are missing or invalid
/// to prevent runtime crashes during development and testing.
class AdHelper {
  // Official Google AdMob Test Unit IDs
  static const String _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIdIos = 'ca-app-pub-3940256099942544/4411468910';

  static const String _testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String _testAppIdIos = 'ca-app-pub-3940256099942544~1458002511';

  /// Returns the AdMob Application ID configured in .env, falling back to test App ID.
  static String get appId {
    final String? id = dotenv.env['ADMOB_APP_ID'];
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (kIsWeb) return '';
    return Platform.isIOS ? _testAppIdIos : _testAppIdAndroid;
  }

  /// Returns the Banner Ad Unit ID configured in .env, falling back to test Banner ID.
  static String get bannerAdUnitId {
    final String? id = dotenv.env['ADMOB_BANNER_ID'];
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (kIsWeb) return '';
    return Platform.isIOS ? _testBannerIdIos : _testBannerIdAndroid;
  }

  /// Returns the Interstitial Ad Unit ID configured in .env, falling back to test Interstitial ID.
  static String get interstitialAdUnitId {
    final String? id = dotenv.env['ADMOB_INTERSTITIAL_ID'];
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (kIsWeb) return '';
    return Platform.isIOS ? _testInterstitialIdIos : _testInterstitialIdAndroid;
  }
}
