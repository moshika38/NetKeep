import 'package:flutter/services.dart';
import 'package:netkeep/services/wireguard_config.dart';

/// Dart-side facade over the native WireGuard relay MethodChannel
/// (`netkeep/vpn`) and its live EventChannel (`netkeep/vpn/events`).
///
/// The native side (HutchVpnService + the official WireGuard Go backend) owns
/// the VpnService: it establishes the TUN with AllowedIPs 0.0.0.0/0 and DNS
/// 1.1.1.1, protects the WireGuard socket against routing loops and routes all
/// app traffic through the tunnel. This facade mirrors that state in-process
/// so the UI can react instantly and stream live stage/statistics updates.
class VpnService {
  VpnService._();

  static const MethodChannel _channel = MethodChannel('netkeep/vpn');
  static const EventChannel _events = EventChannel('netkeep/vpn/events');

  static bool _active = false;

  /// Whether the native tunnel is currently up (last known state).
  static bool get isActive => _active;

  /// Brings the WireGuard relay up with [config].
  ///
  /// Returns a map with `started`, `consentRequired` and possibly `error`.
  /// When `consentRequired` is true the OS consent dialog is shown; the
  /// tunnel starts only after the user approves it.
  static Future<Map<String, dynamic>> start(WireGuardConfig config) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'startWireGuard',
        {'wgQuick': config.toWgQuick()},
      );
      final map = Map<String, dynamic>.from(result ?? const {});
      _active = map['started'] == true;
      return map;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Tears the WireGuard relay down. Safe to call when already disconnected.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopWireGuard');
    } on PlatformException {
      // Non-fatal: the relay is likely already down.
    } finally {
      _active = false;
    }
  }

  /// True when the system has already approved VPN usage for this app.
  static Future<bool> checkPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkVpnPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Re-queries the native service for the real relay state.
  static Future<bool> refreshStatus() async {
    try {
      _active = await _channel.invokeMethod<bool>('getVpnStatus') ?? false;
    } on PlatformException {
      _active = false;
    }
    return _active;
  }

  /// Snapshot of the live relay state: `stage`, `active`, `rxBytes`,
  /// `txBytes` and `handshakeAgeMs`.
  static Future<Map<String, dynamic>> status() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getWgStatus');
      return Map<String, dynamic>.from(result ?? const {});
    } on PlatformException {
      return const {};
    }
  }

  /// Live stream of `{'type': 'stage', 'stage': ...}` and
  /// `{'type': 'stats', 'rxBytes': ..., 'txBytes': ..., 'handshakeAgeMs': ...}`
  /// events pushed by the native relay.
  static Stream<Map<String, dynamic>> get eventStream {
    return _events.receiveBroadcastStream().map((event) {
      if (event is Map) return Map<String, dynamic>.from(event);
      return const <String, dynamic>{};
    });
  }

  /// Reads platform metadata (device, model, android version, SDK level).
  static Future<Map<String, dynamic>> deviceInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? const {});
    } on PlatformException {
      return const {};
    }
  }
}
