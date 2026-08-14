import 'dart:convert';

import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/services/keep_alive_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _autoClearConsoleKey = 'auto_clear_console';
  static const bool _autoClearConsoleDefault = false;
  static const String _selectedIspUrlKey = 'selected_isp_url';
  static const String showNetworkSpeedKey = 'show_network_speed';
  static const bool _showNetworkSpeedDefault = false;
  static const String _pingIntervalKey = 'ping_interval_seconds';
  static const String _batterySaverKey = 'battery_saver_enabled';

  static const String _keepAliveAutoRestartKey = 'keep_alive_auto_restart';
  static const String _keepAliveConfigKey = 'keep_alive_config';
  static const String _consoleLogsKey = 'console_logs';

  static bool _autoClearConsole = _autoClearConsoleDefault;
  static String _selectedIspUrl = defaultIspUrl;
  static bool _showNetworkSpeed = _showNetworkSpeedDefault;
  static int _pingIntervalSeconds = defaultKeepAliveIntervalSeconds;
  static bool _batterySaverEnabled = false;
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
    _pingIntervalSeconds =
        prefs.getInt(_pingIntervalKey) ?? defaultKeepAliveIntervalSeconds;
    _batterySaverEnabled = prefs.getBool(_batterySaverKey) ?? false;
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

  /// Persisted console log history (newest entry first), so entries survive
  /// app restarts when the "Clear Console" toggle is disabled.
  static Future<List<(String, String)>> getConsoleLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consoleLogsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((entry) {
        final pair = (entry as List).cast<String>();
        return (pair[0], pair[1]);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setConsoleLogs(List<(String, String)> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _consoleLogsKey,
      jsonEncode([
        for (final (time, message) in logs) [time, message],
      ]),
    );
  }

  static bool get showNetworkSpeed => _showNetworkSpeed;

  static Future<void> setShowNetworkSpeed(bool value) async {
    _showNetworkSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(showNetworkSpeedKey, value);
  }

  /// Selected ping interval in seconds. Stored independently of the running
  /// service so the Home Screen restores it even when the service is OFF.
  static int get pingIntervalSeconds => _pingIntervalSeconds;

  static Future<void> setPingIntervalSeconds(int value) async {
    _pingIntervalSeconds = value.clamp(1, 3600).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pingIntervalKey, _pingIntervalSeconds);
  }

  /// Whether Battery Saver is enabled. Kept independent of the running
  /// service so the toggle survives app restarts.
  static bool get batterySaverEnabled => _batterySaverEnabled;

  static Future<void> setBatterySaverEnabled(bool value) async {
    _batterySaverEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_batterySaverKey, value);
  }

  static String get selectedIspUrl => _selectedIspUrl;

  static Future<void> setSelectedIspUrl(String url) async {
    _selectedIspUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedIspUrlKey, url);
  }
}
