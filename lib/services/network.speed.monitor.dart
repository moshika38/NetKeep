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
  static const MethodChannel _statsChannel = MethodChannel('netkeep/network_stats');
  static const MethodChannel _speedNotificationChannel = MethodChannel('netkeep/speed_notification');

  /// Number of consecutive samples averaged before a value is reported. Kept
  /// short (sub-second sampling + continuously advancing counters) so the
  /// status-bar readout tracks real-time throughput without visible lag.
  static const int _smoothingSamples = 3;

  int? _lastRxBytes;
  int? _lastTxBytes;
  DateTime? _lastSampleAt;
  final List<int> _downloadHistory = [];
  final List<int> _uploadHistory = [];

  /// Forgets the previous baseline so the next [sample] establishes a fresh
  /// reference point instead of measuring across a (potentially long) gap.
  void reset() {
    _lastRxBytes = null;
    _lastTxBytes = null;
    _lastSampleAt = null;
    _downloadHistory.clear();
    _uploadHistory.clear();
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

    _downloadHistory.add(downloadBps);
    _uploadHistory.add(uploadBps);
    while (_downloadHistory.length > _smoothingSamples) {
      _downloadHistory.removeAt(0);
    }
    while (_uploadHistory.length > _smoothingSamples) {
      _uploadHistory.removeAt(0);
    }

    final smoothedDownload = _average(_downloadHistory);
    final smoothedUpload = _average(_uploadHistory);

    await _updateSpeedIcon(smoothedDownload, smoothedUpload);
    return (smoothedDownload, smoothedUpload);
  }

  static int _average(List<int> values) {
    if (values.isEmpty) return 0;
    var total = 0;
    for (final value in values) {
      total += value;
    }
    return (total / values.length).round();
  }

  Future<(int, int)?> _readCounters() async {
    try {
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

  /// Formats a raw byte/second value as a human friendly network line used by
  /// the console and status bar.
  static String formatDownload(int bytesPerSecond) {
    if (bytesPerSecond < 0) return '--';
    if (bytesPerSecond == 0) return '0 B/s';
    return '${_format(bytesPerSecond)}/s ↓';
  }

  static String formatUpload(int bytesPerSecond) {
    if (bytesPerSecond < 0) return '--';
    if (bytesPerSecond == 0) return '0 B/s';
    return '${_format(bytesPerSecond)}/s ↑';
  }

  static String _format(int bytesPerSecond) {
    final double kbps = bytesPerSecond / 1024.0;
    if (kbps < 10) return '$bytesPerSecond B';
    if (kbps < 1000) return '${kbps.toStringAsFixed(0)} KB';
    final double mbps = kbps / 1024.0;
    if (mbps < 1000) return '${mbps.toStringAsFixed(1)} MB';
    final double gbps = mbps / 1024.0;
    return '${gbps.toStringAsFixed(2)} GB';
  }
}
