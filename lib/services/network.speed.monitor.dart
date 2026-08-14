import 'package:flutter/services.dart';

/// Live device-wide network speed, measured through Android's native
/// `TrafficStats` byte counters.
///
/// The counters are exposed over the `netkeep/network_stats` method channel
/// (bridged by the `netkeep_traffic_stats` plugin) and represent the
/// cumulative system-wide RX/TX bytes since boot. Speed is the delta between
/// two consecutive samples divided by the elapsed time - the same measurement
/// the previous native keep-alive service used. It needs no special
/// permission.
///
/// A rolling average over the last few samples smooths out bursts and the
/// occasionally non-advancing OS counters, so the displayed value does not
/// drop to zero between refinements.
class NetworkSpeedMonitor {
  static const MethodChannel _statsChannel = MethodChannel(
    'netkeep/network_stats',
  );
  static const MethodChannel _speedNotificationChannel = MethodChannel(
    'netkeep/speed_notification',
  );

  /// Smoothing factor for Exponential Moving Average (EMA). Higher values adapt
  /// faster to changes, lower values provide smoother transitions.
  static const double _emaAlpha = 0.45;

  int? _lastRxBytes;
  int? _lastTxBytes;
  DateTime? _lastSampleAt;
  double? _emaDownload;
  double? _emaUpload;
  int _consecutiveZeroTicks = 0;

  /// Forgets the previous baseline so the next [sample] establishes a fresh
  /// reference point instead of measuring across a (potentially long) gap.
  void reset() {
    _lastRxBytes = null;
    _lastTxBytes = null;
    _lastSampleAt = null;
    _emaDownload = null;
    _emaUpload = null;
    _consecutiveZeroTicks = 0;
  }

  /// Samples the current TrafficStats counters and returns the smoothed
  /// (download, upload) bytes-per-second since the previous sample, or null
  /// when no measurement is possible yet (channel unavailable, first call
  /// establishing the baseline, or counters reset by the OS).
  Future<(int, int)?> sample() async {
    final counters = await _readCounters();
    if (counters == null) return null;

    final now = DateTime.now();
    final lastAt = _lastSampleAt;
    final lastRx = _lastRxBytes;
    final lastTx = _lastTxBytes;

    _lastRxBytes = counters.$1;
    _lastTxBytes = counters.$2;
    _lastSampleAt = now;

    if (lastAt == null || lastRx == null || lastTx == null) return null;

    final elapsedMs = now.difference(lastAt).inMilliseconds;
    if (elapsedMs <= 0) return null;

    final rxDelta = counters.$1 - lastRx;
    final txDelta = counters.$2 - lastTx;
    // Counter reset / unsupported devices: keep the baseline but skip the
    // sample instead of reporting a bogus zero speed.
    if (rxDelta < 0 || txDelta < 0) return null;

    final downloadBps = (rxDelta * 1000 / elapsedMs).round();
    final uploadBps = (txDelta * 1000 / elapsedMs).round();

    // Use Exponential Moving Average (EMA) to smooth out OS kernel buffer
    // reporting gaps. Single-tick zero readings during active transfers are
    // absorbed, while continuous zero ticks smoothly decay to zero.
    final bool isInstantZero = (downloadBps == 0 && uploadBps == 0);
    if (isInstantZero) {
      _consecutiveZeroTicks++;
    } else {
      _consecutiveZeroTicks = 0;
    }

    if (_emaDownload == null || _consecutiveZeroTicks >= 4) {
      _emaDownload = downloadBps.toDouble();
      _emaUpload = uploadBps.toDouble();
    } else {
      _emaDownload = _emaAlpha * downloadBps + (1.0 - _emaAlpha) * _emaDownload!;
      _emaUpload = _emaAlpha * uploadBps + (1.0 - _emaAlpha) * _emaUpload!;
    }

    final smoothedDownload = _emaDownload!.round();
    final smoothedUpload = _emaUpload!.round();

    await _updateSpeedIcon(smoothedDownload, smoothedUpload);
    return (smoothedDownload, smoothedUpload);
  }

  Future<(int, int)?> _readCounters() async {
    try {
      final list = await _statsChannel.invokeMethod<List<dynamic>>('getTrafficBytes');
      if (list != null && list.length >= 2) {
        return (list[0] as int, list[1] as int);
      }
      final rx = await _statsChannel.invokeMethod<int>('getRxBytes');
      final tx = await _statsChannel.invokeMethod<int>('getTxBytes');
      if (rx == null || tx == null) return null;
      return (rx, tx);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _updateSpeedIcon(int downloadBps, int uploadBps) async {
    try {
      await _speedNotificationChannel.invokeMethod<void>('updateSpeedIcon', {
        'downloadBytesPerSecond': downloadBps,
        'uploadBytesPerSecond': uploadBps,
      });
    } on PlatformException {
      // Notification update failed; the speed readout itself stays valid.
    } on MissingPluginException {
      // Plugin not attached yet; the ticker will retry on the next sample.
    }
  }

  /// Hidden speed notification helper shared with the engine.
  Future<void> hideSpeedIcon() {
    return _speedNotificationChannel.invokeMethod<void>('hideSpeedIcon');
  }

  /// Updates the keep-alive notification title/content through the unified
  /// notification builder so the foreground-service text stays live without
  /// re-posting via the flutter_background_service plugin (which would fire a
  /// competing `notify(1000)` with default settings and clobber the speed
  /// icon/config).
  Future<void> updateContent({required String title, required String content}) {
    return _speedNotificationChannel.invokeMethod<void>('updateContent', {
      'title': title,
      'content': content,
    });
  }
}
