import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _defaultTargetUrl = 'oneapp.hutch.lk';
const String _defaultIspName = 'Hutch';

const int _speedEnabledIntervalMs = 1000;
const int _speedDisabledIntervalMs = 5000;

const MethodChannel _networkStatsChannel = MethodChannel('netkeep/network_stats');
const MethodChannel _statusBarIconChannel = MethodChannel('netkeep/status_bar_icon');

// Background Task Entry Point
@pragma('vm:entry-point')
void keepAliveTaskCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(KeepAliveTaskHandler());
}

class KeepAliveTaskHandler extends TaskHandler {
  String _targetUrl = _defaultTargetUrl;
  String _ispName = _defaultIspName;

  bool _showNetworkSpeed = true;

  int? _previousRxBytes;
  int? _previousTxBytes;

  int _downloadBytesPerSec = 0;
  int _uploadBytesPerSec = 0;
  int? _lastPingMs;
  bool _pingInFlight = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _previousRxBytes = null;
    _previousTxBytes = null;

    // Sync the saved preference into the background isolate. This covers
    // service auto-restarts where no config data has been pushed yet.
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? saved = prefs.getBool(AppPreferences.showNetworkSpeedKey);
      if (saved != null && saved != _showNetworkSpeed) {
        _showNetworkSpeed = saved;
        _applyInterval();
      }
    } catch (_) {
      // Fall back to the value pushed via sendDataToTask.
    }

    _pushNotification();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Runs every 1000ms (speed enabled) or 5000ms (speed disabled).
    // Reads the device-wide byte counters through the native TrafficStats
    // MethodChannel, computes the speed as the delta between consecutive
    // ticks, and updates the notification.
    //
    // When "Show Network Speed" is disabled the TrafficStats fetching and
    // speed calculation are skipped entirely to conserve battery and CPU.
    if (_showNetworkSpeed) {
      final NetworkTraffic? current = await _fetchNetworkTraffic();

      if (current != null) {
        // First tick only stores the baseline counters to avoid reporting the
        // cumulative bytes since boot as an artificial speed spike.
        if (_previousRxBytes == null || _previousTxBytes == null) {
          _previousRxBytes = current.rxBytes;
          _previousTxBytes = current.txBytes;
        } else {
          final int rxDelta = current.rxBytes - _previousRxBytes!;
          final int txDelta = current.txBytes - _previousTxBytes!;

          // Fail-safe: ignore negative/zero deltas without breaking the loop.
          _downloadBytesPerSec = rxDelta > 0 ? rxDelta : 0;
          _uploadBytesPerSec = txDelta > 0 ? txDelta : 0;

          _previousRxBytes = current.rxBytes;
          _previousTxBytes = current.txBytes;
        }
      }
    }

    _pushNotification();

    // Ping is measured in the background so it never blocks the speed tick.
    if (!_pingInFlight) {
      _pingInFlight = true;
      unawaited(_refreshPing());
    }
  }

  Future<void> _refreshPing() async {
    try {
      _lastPingMs = await _measurePing(_targetUrl);
      _pushNotification();
    } finally {
      _pingInFlight = false;
    }
  }

  Future<void> _pushNotification() async {
    final String title = _showNetworkSpeed
        ? '⬇ ${_formatSpeed(_downloadBytesPerSec)}  ⬆ ${_formatSpeed(_uploadBytesPerSec)}'
        : 'NetKeep Active';
    final String text = 'ISP: $_ispName | '
        'Ping: ${_lastPingMs == null ? 'Failed' : '${_lastPingMs}ms'}';

    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );

    // Update the dynamic status-bar small icon with the live download speed.
    // The plugin rebuilds the notification with the static icon above, so this
    // runs afterwards to make the speed bitmap win until the next tick. Raw
    // bytes are sent so the native side can format and render the bitmap.
    if (_showNetworkSpeed) {
      try {
        await _statusBarIconChannel.invokeMethod<void>(
          'setDownloadSpeed',
          {'bytesPerSecond': _downloadBytesPerSec},
        );
      } catch (_) {
        // Native channel unavailable (older build) - keep static icon.
      }
    }
  }

  // Applies the repeat interval that matches the current speed setting and
  // resets the baseline so re-enabling speed never spikes.
  void _applyInterval() {
    final int intervalMs =
        _showNetworkSpeed ? _speedEnabledIntervalMs : _speedDisabledIntervalMs;

    FlutterForegroundTask.updateService(
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(intervalMs),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: true,
      ),
    );

    if (_showNetworkSpeed) {
      _previousRxBytes = null;
      _previousTxBytes = null;
    }
  }

  Future<int?> _measurePing(String target) async {
    final String host = _extractHost(target);
    if (host.isEmpty) return null;

    if (Platform.isAndroid) {
      try {
        final ProcessResult result = await Process.run(
          'ping',
          ['-c', '1', '-W', '1', host],
        ).timeout(const Duration(seconds: 2));
        if (result.exitCode == 0) {
          final String output = result.stdout.toString();
          final RegExpMatch? match =
              RegExp(r'time[=<]\s*(\d+(?:\.\d+)?)').firstMatch(output);
          if (match != null) {
            final int? parsed = double.tryParse(match.group(1)!)?.round();
            if (parsed != null) return parsed;
          }
        }
      } catch (_) {
        // Fall through to DNS lookup timing.
      }
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 2));
      return addresses.isNotEmpty ? stopwatch.elapsedMilliseconds : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _previousRxBytes = null;
    _previousTxBytes = null;
  }

  @override
  void onReceiveData(Object data) {
    // Map payload: {'ispName': ..., 'targetUrl': ..., 'showNetworkSpeed': ...}
    if (data is Map) {
      final Object? name = data['ispName'];
      final Object? url = data['targetUrl'];
      final Object? speed = data['showNetworkSpeed'];

      if (name is String && name.isNotEmpty) _ispName = name;
      if (url is String && url.isNotEmpty) _targetUrl = url;

      if (speed is bool && speed != _showNetworkSpeed) {
        _showNetworkSpeed = speed;
        _applyInterval();
      }

      _pushNotification();
      return;
    }

    if (data is! String) return;
    final List<String> parts = data.split('|');
    if (parts.length >= 2) {
      final String name = parts[0].trim();
      final String url = parts[1].trim();
      if (name.isNotEmpty) _ispName = name;
      if (url.isNotEmpty) _targetUrl = url;
    } else {
      final String url = parts.first.trim();
      if (url.isNotEmpty) _targetUrl = url;
    }
  }
}

class NetworkTraffic {
  final int rxBytes;
  final int txBytes;

  const NetworkTraffic({required this.rxBytes, required this.txBytes});
}

// Reads device-wide byte counters through the native TrafficStats
// MethodChannel. Returns null when the channel is unavailable.
Future<NetworkTraffic?> _fetchNetworkTraffic() async {
  if (!Platform.isAndroid) return null;
  try {
    final int rxBytes =
        await _networkStatsChannel.invokeMethod<int>('getRxBytes') ?? 0;
    final int txBytes =
        await _networkStatsChannel.invokeMethod<int>('getTxBytes') ?? 0;
    return NetworkTraffic(rxBytes: rxBytes, txBytes: txBytes);
  } catch (_) {
    return null;
  }
}

String _formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond < 1024) return '$bytesPerSecond B/s';
  final double kb = bytesPerSecond / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB/s';
  final double mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB/s';
  return '${(mb / 1024).toStringAsFixed(2)} GB/s';
}

String _extractHost(String url) {
  String value = url.trim();
  value = value.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
  final int slash = value.indexOf('/');
  if (slash >= 0) value = value.substring(0, slash);
  return value;
}

class KeepAliveManager {
  // Initializes the foreground task configuration (notification channel etc.).
  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'netkeep_keepalive_channel',
        channelName: 'NetKeep Keep-Alive Service',
        channelDescription:
            'Monitors live network speed and connection latency.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        showWhen: true,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_taskIntervalMs()),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: true,
      ),
    );
  }

  static int _taskIntervalMs() => AppPreferences.showNetworkSpeed
      ? _speedEnabledIntervalMs
      : _speedDisabledIntervalMs;

  static Future<bool> isServiceRunning() {
    return FlutterForegroundTask.isRunningService;
  }

  // Starts the keep-alive service. Handles the Android 13+ notification
  // permission before starting.
  static Future<bool> startService({
    required String ispName,
    required String targetUrl,
  }) async {
    initService();

    if (await FlutterForegroundTask.isRunningService) {
      updateTargetUrl(ispName: ispName, targetUrl: targetUrl);
      return true;
    }

    NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      notificationPermission =
          await FlutterForegroundTask.requestNotificationPermission();
    }
    if (notificationPermission != NotificationPermission.granted) {
      return false;
    }

    final bool showSpeed = AppPreferences.showNetworkSpeed;
    final ServiceRequestResult result = await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: showSpeed ? '⬇ 0 B/s  ⬆ 0 B/s' : 'NetKeep Active',
      notificationText: 'Starting keep-alive service...',
      notificationIcon: const NotificationIcon(
        metaDataName: 'netkeep_keepalive_icon',
      ),
      callback: keepAliveTaskCallback,
    );

    if (result is ServiceRequestSuccess) {
      updateTargetUrl(ispName: ispName, targetUrl: targetUrl);
      pushInitialSpeedIcon();
      return true;
    }
    return false;
  }

  // Pushes the very first "0K" speed bitmap immediately after the service
  // starts. The plugin's base notification uses an invisible placeholder icon,
  // so this dynamic bitmap is what the status bar shows right away (and every
  // tick afterwards). No-op when speed display is disabled.
  static void pushInitialSpeedIcon() {
    if (!AppPreferences.showNetworkSpeed) return;
    try {
      _statusBarIconChannel.invokeMethod<void>(
        'setDownloadSpeed',
        {'bytesPerSecond': 0},
      );
    } catch (_) {
      // Native channel unavailable (older build) - ignore.
    }
  }

  static Future<bool> stopService() async {
    if (!(await FlutterForegroundTask.isRunningService)) return true;
    final ServiceRequestResult result =
        await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  // Dynamically updates the target ISP + URL in the running task without
  // restarting the service.
  static void updateTargetUrl({
    required String ispName,
    required String targetUrl,
  }) {
    FlutterForegroundTask.sendDataToTask({
      'ispName': ispName,
      'targetUrl': targetUrl,
      'showNetworkSpeed': AppPreferences.showNetworkSpeed,
    });
  }

  // Dynamically pushes the "Show Network Speed" preference to the running
  // background isolate so it can update the interval and notification layout
  // immediately. No-op when the service is not running.
  static void updateShowNetworkSpeed(bool value) {
    FlutterForegroundTask.sendDataToTask({'showNetworkSpeed': value});
  }
}
