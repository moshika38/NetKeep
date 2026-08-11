import 'dart:convert';

import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/services/keep_alive_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _autoClearConsoleKey = 'auto_clear_console';
  static const bool _autoClearConsoleDefault = false;
  static const String _selectedIspUrlKey = 'selected_isp_url';
  static const String showNetworkSpeedKey = 'show_network_speed';
  static const bool _showNetworkSpeedDefault = true;

  static const String _keepAliveAutoRestartKey = 'keep_alive_auto_restart';
  static const String _keepAliveConfigKey = 'keep_alive_config';

  static bool _autoClearConsole = _autoClearConsoleDefault;
  static String _selectedIspUrl = defaultIspUrl;
  static bool _showNetworkSpeed = _showNetworkSpeedDefault;
  static bool _keepAliveAutoRestart = false;
  static KeepAliveConfigData _keepAliveConfig =
      const KeepAliveConfigData(
        targetUrl: defaultKeepAliveTargetUrl,
        ispName: 'Hutch',
      );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoClearConsole =
        prefs.getBool(_autoClearConsoleKey) ?? _autoClearConsoleDefault;
    _selectedIspUrl = prefs.getString(_selectedIspUrlKey) ?? defaultIspUrl;
    _showNetworkSpeed =
        prefs.getBool(showNetworkSpeedKey) ?? _showNetworkSpeedDefault;
    _keepAliveAutoRestart =
        prefs.getBool(_keepAliveAutoRestartKey) ?? false;
    _keepAliveConfig = _readKeepAliveConfig(prefs);
  }

  /// Whether the keep-alive service was running when the app last stopped and
  /// should therefore be resumed automatically after a reboot. Set by the UI
  /// isolate and checked by the background isolate on every (re)start.
  static bool get keepAliveAutoRestart => _keepAliveAutoRestart;

  static Future<void> setKeepAliveAutoRestart(bool value) async {
    _keepAliveAutoRestart = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepAliveAutoRestartKey, value);
  }

  /// Last known keep-alive configuration, restored by the background isolate
  /// after an OS-initiated restart (reboot / package upgrade).
  static KeepAliveConfigData get keepAliveConfig => _keepAliveConfig;

  static Future<void> setKeepAliveConfig(KeepAliveConfigData config) async {
    _keepAliveConfig = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keepAliveConfigKey, jsonEncode(config.toMap()));
  }

  static KeepAliveConfigData _readKeepAliveConfig(SharedPreferences prefs) {
    final raw = prefs.getString(_keepAliveConfigKey);
    if (raw == null || raw.isEmpty) {
      return const KeepAliveConfigData(
        targetUrl: defaultKeepAliveTargetUrl,
        ispName: 'Hutch',
      );
    }
    try {
      return KeepAliveConfigData.fromMap(
        (jsonDecode(raw) as Map).cast<dynamic, dynamic>(),
      );
    } catch (_) {
      return const KeepAliveConfigData(
        targetUrl: defaultKeepAliveTargetUrl,
        ispName: 'Hutch',
      );
    }
  }

  static bool get autoClearConsole => _autoClearConsole;

  static Future<void> setAutoClearConsole(bool value) async {
    _autoClearConsole = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoClearConsoleKey, value);
  }

  static bool get showNetworkSpeed => _showNetworkSpeed;

  static Future<void> setShowNetworkSpeed(bool value) async {
    _showNetworkSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(showNetworkSpeedKey, value);
  }

  static String get selectedIspUrl => _selectedIspUrl;

  static Future<void> setSelectedIspUrl(String url) async {
    _selectedIspUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedIspUrlKey, url);
  }
}
