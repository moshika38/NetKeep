import 'package:netkeep/services/isp.config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _autoClearConsoleKey = 'auto_clear_console';
  static const bool _autoClearConsoleDefault = false;
  static const String _selectedIspUrlKey = 'selected_isp_url';
  static const String showNetworkSpeedKey = 'show_network_speed';
  static const bool _showNetworkSpeedDefault = true;
  static const String _vpnTunnelModeKey = 'vpn_tunnel_mode';
  static const bool _vpnTunnelModeDefault = true;

  static bool _autoClearConsole = _autoClearConsoleDefault;
  static String _selectedIspUrl = defaultIspUrl;
  static bool _showNetworkSpeed = _showNetworkSpeedDefault;
  static bool _vpnTunnelMode = _vpnTunnelModeDefault;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoClearConsole =
        prefs.getBool(_autoClearConsoleKey) ?? _autoClearConsoleDefault;
    _selectedIspUrl = prefs.getString(_selectedIspUrlKey) ?? defaultIspUrl;
    _showNetworkSpeed =
        prefs.getBool(showNetworkSpeedKey) ?? _showNetworkSpeedDefault;
    _vpnTunnelMode =
        prefs.getBool(_vpnTunnelModeKey) ?? _vpnTunnelModeDefault;
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

  /// When true, starting the keep-alive service also brings the WireGuard
  /// tunnel (Cloudflare WARP) up so all pings route through the VPN.
  static bool get vpnTunnelMode => _vpnTunnelMode;

  static Future<void> setVpnTunnelMode(bool value) async {
    _vpnTunnelMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vpnTunnelModeKey, value);
  }
}
