import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.buildNumber.isNotEmpty) {
        return 'v${info.version}+${info.buildNumber}';
      }
      return 'v${info.version}';
    } catch (_) {
      return 'v1.0.1+2';
    }
  }
}
