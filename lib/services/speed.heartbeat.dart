import 'dart:async';

import 'package:dio/dio.dart';
import 'package:netkeep/services/keep_alive_config.dart';
import 'package:netkeep/services/network.speed.monitor.dart';

/// Independent network-speed heartbeat, fully decoupled from the keep-alive
/// ping loop.
///
/// While active it fires a lightweight HTTPS HEAD request every 600ms over a
/// plain direct [Dio] socket (no VPN/TUN interface). The sub-second cadence
/// keeps the underlying `dart:io` connection pool from idling out, so the
/// socket stays warm and Android's system-wide `TrafficStats` byte counters
/// advance continuously - the status-bar speed readout refreshes almost
/// immediately instead of lagging behind spikes. On every tick the smoothed
/// download/upload throughput is sampled and pushed into the status-bar speed
/// notification.
///
/// Lifecycle is owned entirely by the "Display Network Speed" toggle: [start]
/// begins the loop and [stop] cancels it completely (battery/network usage
/// drops to zero). It does not depend on whether the main Ping Service is
/// running or stopped.
class SpeedHeartbeat {
  SpeedHeartbeat({required this.targetUrl});

  static const Duration _tickInterval = Duration(milliseconds: 600);
  static const Duration _connectTimeout = Duration(seconds: 5);
  static const Duration _ioTimeout = Duration(seconds: 3);

  final String targetUrl;

  final NetworkSpeedMonitor _speedMonitor = NetworkSpeedMonitor();

  Dio? _dio;
  Timer? _timer;
  bool _stopped = true;
  bool _tickInFlight = false;

  bool get isActive => !_stopped;

  Dio get _client => _dio ??= Dio(
    BaseOptions(
      connectTimeout: _connectTimeout,
      sendTimeout: _ioTimeout,
      receiveTimeout: _ioTimeout,
      validateStatus: (_) => true,
    ),
  );

  /// Starts the heartbeat. Idempotent: repeated calls while already running
  /// are no-ops.
  void start() {
    if (!_stopped) return;
    _stopped = false;
    _speedMonitor.reset();
    _timer ??= Timer.periodic(_tickInterval, (_) => _tick());
  }

  /// Stops the heartbeat completely and hides the status-bar speed glyph.
  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
    await _speedMonitor.hideSpeedIcon();
  }

  Future<void> _tick() async {
    if (_stopped || _tickInFlight) return;
    _tickInFlight = true;
    try {
      await _fireTraffic();
      await _speedMonitor.sample();
    } catch (_) {
      // A heartbeat tick must never crash the background isolate; the next
      // tick retries.
    } finally {
      _tickInFlight = false;
    }
  }

  /// Fires one lightweight HEAD request so real bytes move in and out of the
  /// socket every tick. HEAD keeps the payload to a minimal, constant amount
  /// (request/response headers over the warm keep-alive connection) while still
  /// forcing Android's byte counters to advance - enough for the OS to see the
  /// throughput change immediately without a data-hungry body. Falls back to
  /// the standard keep-alive fallback targets when the primary ISP target is
  /// unreachable, so traffic keeps flowing (and the speed readout stays live)
  /// even during an ISP outage. [NetworkSpeedMonitor.sample] is the only place
  /// that ever touches the speed notification.
  Future<void> _fireTraffic() async {
    try {
      await _client.head<dynamic>(targetUrl);
      return;
    } on DioException {
      // Primary target unreachable - fall through to the fallbacks below.
    }
    for (final fallback in keepAliveFallbackTargets) {
      try {
        await _client.head<dynamic>(fallback);
        return;
      } on DioException {
        // Keep trying the remaining fallbacks.
      }
    }
  }
}
