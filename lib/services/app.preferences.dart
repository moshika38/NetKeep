import 'package:netkeep/services/isp.config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _autoClearConsoleKey = 'auto_clear_console';
  static const bool _autoClearConsoleDefault = false;
  static const String _selectedIspUrlKey = 'selected_isp_url';

  static bool _autoClearConsole = _autoClearConsoleDefault;
  static String _selectedIspUrl = defaultIspUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoClearConsole =
        prefs.getBool(_autoClearConsoleKey) ?? _autoClearConsoleDefault;
    _selectedIspUrl = prefs.getString(_selectedIspUrlKey) ?? defaultIspUrl;
  }

  static bool get autoClearConsole => _autoClearConsole;

  static Future<void> setAutoClearConsole(bool value) async {
    _autoClearConsole = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoClearConsoleKey, value);
  }

  static String get selectedIspUrl => _selectedIspUrl;

  static Future<void> setSelectedIspUrl(String url) async {
    _selectedIspUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedIspUrlKey, url);
  }
}
