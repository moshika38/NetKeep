import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final bool immediateAllowed;
  final int? availableVersionCode;
  final String? error;

  const AppUpdateInfo({
    required this.updateAvailable,
    required this.immediateAllowed,
    this.availableVersionCode,
    this.error,
  });

  factory AppUpdateInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppUpdateInfo(
      updateAvailable: map['updateAvailable'] as bool? ?? false,
      immediateAllowed: map['immediateAllowed'] as bool? ?? false,
      availableVersionCode: (map['availableVersionCode'] as num?)?.toInt(),
      error: map['error'] as String?,
    );
  }
}

class AppUpdateService {
  static const MethodChannel _channel = MethodChannel('netkeep/app_update');

  /// Checks if a mandatory update is available on Google Play Store.
  static Future<AppUpdateInfo> checkForUpdate() async {
    if (!Platform.isAndroid || kIsWeb) {
      return const AppUpdateInfo(
        updateAvailable: false,
        immediateAllowed: false,
      );
    }
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkForUpdate',
      );
      if (res != null) {
        return AppUpdateInfo.fromMap(res);
      }
    } on PlatformException catch (e) {
      debugPrint('AppUpdateService: Error checking for update: ${e.message}');
    } on MissingPluginException {
      debugPrint('AppUpdateService: MethodChannel missing');
    }
    return const AppUpdateInfo(
      updateAvailable: false,
      immediateAllowed: false,
    );
  }

  /// Triggers the Google Play Immediate Update flow.
  static Future<bool> performImmediateUpdate() async {
    if (!Platform.isAndroid || kIsWeb) {
      return false;
    }
    try {
      final success = await _channel.invokeMethod<bool>(
        'performImmediateUpdate',
      );
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('AppUpdateService: Error performing immediate update: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
