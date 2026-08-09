import 'dart:async';

import 'package:netkeep/services/wireguard_config.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

/// Thin Dart facade over [WireGuardFlutter], the plugin that drives the
/// official WireGuard tunnel (com.wireguard.android:tunnel) via a real
/// Android VpnService.
///
/// The screen talks to this class so it never touches the plugin API
/// directly. Stage names are surfaced as plain strings.
class WireGuardService {
  WireGuardService._();

  static final WireGuardService instance = WireGuardService._();

  final WireGuardFlutterInterface _wg = WireGuardFlutter.instance;
  bool _initialized = false;

  /// Android ignores [providerBundleIdentifier] (it is the iOS extension id).
  static const String _providerBundleId = 'com.example.netkeep';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _wg.initialize(interfaceName: 'wg0', vpnName: 'NetKeep');
    _initialized = true;
  }

  /// Opens the WireGuard tunnel using [config].
  Future<void> connect(WireGuardConfig config) async {
    await _ensureInitialized();
    await _wg.startVpn(
      serverAddress: config.serverAddress,
      wgQuickConfig: config.toWgQuick(),
      providerBundleIdentifier: _providerBundleId,
    );
  }

  /// Tears the tunnel down. Safe to call when already disconnected.
  Future<void> disconnect() async {
    try {
      await _wg.stopVpn();
    } catch (_) {
      // Tunnel is already down.
    }
  }

  Future<bool> isConnected() async {
    try {
      return await _wg.isConnected();
    } catch (_) {
      return false;
    }
  }

  /// Current stage as a string (connected, connecting, disconnected, ...).
  Future<String> stage() async {
    try {
      return (await _wg.stage()).name;
    } catch (_) {
      return 'disconnected';
    }
  }

  /// Pushes the native runtime to re-report its stage.
  Future<void> refreshStage() async {
    try {
      await _wg.refreshStage();
    } catch (_) {}
  }

  /// Live stream of stage transitions.
  Stream<String> get stageStream =>
      _wg.vpnStageSnapshot.map((stage) => stage.name);

  /// Live stream of traffic statistics.
  Stream<Map<String, dynamic>> get trafficStream => _wg.trafficSnapshot;

  /// Snapshot of traffic statistics.
  Future<Map<String, dynamic>> trafficStats() async {
    try {
      return await _wg.trafficStats();
    } catch (_) {
      return const {};
    }
  }

  /// Whether the system has already approved VPN usage for this app.
  Future<bool> checkPermission() async {
    try {
      return await _wg.checkVpnPermission();
    } catch (_) {
      return false;
    }
  }
}
