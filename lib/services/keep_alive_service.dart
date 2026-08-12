import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/keep_alive_config.dart';
import 'package:netkeep/services/network.speed.monitor.dart';
import 'package:netkeep/services/ping.client.dart';

/// Background-isolate entry point, invoked by [flutter_background_service]
/// whenever the Android foreground service is (re)started - including the
/// automatic restart after a device reboot. It owns the ping loop entirely in
/// Dart, so the service keeps probing while the UI is closed.
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final engine = KeepAliveEngine(service);
  await engine.init();

  service.on('appStart').listen(engine.applyConfig);
  service.on('appUpdateConfig').listen(engine.applyConfig);
  service.on('appStop').listen((_) => engine.stop());
}

/// iOS background-fetch counterpart. Kept minimal; keep-alive is Android-only.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

enum KeepAliveEventType { probe, status, speed }

/// Rolling statistics of the keep-alive loop. Tracked inside the background
/// isolate and pushed to the UI with every event so counters survive activity
/// recreation and configuration changes.
class KeepAliveStats {
  final int totalPings;
  final int successfulPings;
  final int failedPings;
  final int totalLatencyMs;
  final int consecutiveFailures;
  final int totalFailures;

  const KeepAliveStats({
    required this.totalPings,
    required this.successfulPings,
    required this.failedPings,
    required this.totalLatencyMs,
    required this.consecutiveFailures,
    required this.totalFailures,
  });

  static const KeepAliveStats empty = KeepAliveStats(
    totalPings: 0,
    successfulPings: 0,
    failedPings: 0,
    totalLatencyMs: 0,
    consecutiveFailures: 0,
    totalFailures: 0,
  );

  int get averageLatencyMs =>
      successfulPings == 0 ? 0 : totalLatencyMs ~/ successfulPings;

  KeepAliveStats record(PingResult result) {
    final ok = result.ok;
    return KeepAliveStats(
      totalPings: totalPings + 1,
      successfulPings: successfulPings + (ok ? 1 : 0),
      failedPings: failedPings + (ok ? 0 : 1),
      totalLatencyMs: totalLatencyMs + (ok ? result.rttMs : 0),
      consecutiveFailures: ok ? 0 : consecutiveFailures + 1,
      totalFailures: totalFailures + (ok ? 0 : 1),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'totalPings': totalPings,
    'successfulPings': successfulPings,
    'failedPings': failedPings,
    'totalLatencyMs': totalLatencyMs,
    'averageLatencyMs': averageLatencyMs,
    'consecutiveFailures': consecutiveFailures,
    'totalFailures': totalFailures,
  };

  factory KeepAliveStats.fromMap(Map<dynamic, dynamic> map) {
    final total = (map['totalPings'] as num?)?.toInt() ?? 0;
    final successful = (map['successfulPings'] as num?)?.toInt() ?? 0;
    return KeepAliveStats(
      totalPings: total,
      successfulPings: successful,
      failedPings: (map['failedPings'] as num?)?.toInt() ?? 0,
      totalLatencyMs: (map['totalLatencyMs'] as num?)?.toInt() ?? 0,
      consecutiveFailures:
          (map['consecutiveFailures'] as num?)?.toInt() ?? 0,
      totalFailures: (map['totalFailures'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A single event pushed from the background isolate over the plugin stream.
/// `probe` events carry a formatted console line plus the transport result and
/// latency; `status` events carry the current running state (used to reconnect
/// the UI after the activity is recreated or the app resumes); `speed` events
/// carry the latest measured download/upload throughput.
class KeepAliveEvent {
  final KeepAliveEventType type;
  final String? time;
  final String? message;
  final bool? running;
  final int? intervalSeconds;
  final bool? batterySaverEnabled;
  final bool? showNetworkSpeed;
  final bool? success;
  final int? latency;
  final int? downloadSpeed;
  final int? uploadSpeed;
  final KeepAliveStats? stats;

  const KeepAliveEvent({
    required this.type,
    this.time,
    this.message,
    this.running,
    this.intervalSeconds,
    this.batterySaverEnabled,
    this.showNetworkSpeed,
    this.success,
    this.latency,
    this.downloadSpeed,
    this.uploadSpeed,
    this.stats,
  });

  factory KeepAliveEvent.fromMap(Map<dynamic, dynamic> map) {
    return KeepAliveEvent(
      type: switch (map['type']) {
        'status' => KeepAliveEventType.status,
        'speed' => KeepAliveEventType.speed,
        _ => KeepAliveEventType.probe,
      },
      time: map['time'] as String?,
      message: map['message'] as String?,
      running: map['running'] as bool?,
      intervalSeconds: (map['intervalSeconds'] as num?)?.toInt(),
      batterySaverEnabled: map['batterySaverEnabled'] as bool?,
      showNetworkSpeed: map['showNetworkSpeed'] as bool?,
      success: map['success'] as bool?,
      latency: (map['latency'] as num?)?.toInt(),
      downloadSpeed: (map['downloadSpeed'] as num?)?.toInt(),
      uploadSpeed: (map['uploadSpeed'] as num?)?.toInt(),
      stats: KeepAliveStats.fromMap(map),
    );
  }
}

/// Flutter-side facade for the Dart keep-alive foreground service.
///
/// Start/stop/configuration are forwarded to the background isolate over
/// [flutter_background_service]'s message pipes; probe results, running state
/// and live speed stream back over [events]. The UI never touches the
/// background loop as a Dart object - on Android the loop lives in its own
/// isolate.
class KeepAliveManager {
  static bool get _isAndroid => Platform.isAndroid;

  static const MethodChannel _platformChannel = MethodChannel('netkeep/platform');
  static const MethodChannel _wakelockChannel = MethodChannel('netkeep/wakelock');

  static Future<bool>? _configureFuture;
  static Stream<KeepAliveEvent>? _events;

  /// Live probe/status/speed events from the background isolate.
  static Stream<KeepAliveEvent> get events {
    return _events ??= FlutterBackgroundService()
        .on('keepAliveEvent')
        .where((event) => event != null)
        .map((event) => KeepAliveEvent.fromMap(event!))
        .asBroadcastStream();
  }

  /// Registers the background-service handler with the plugin. Idempotent and
  /// awaited by [startService] so the pipe is always live before a start.
  static Future<void> initService() async {
    if (!_isAndroid) return;
    _configureFuture ??= _configure();
    await _configureFuture;
  }

  static Future<bool> _configure() async {
    return FlutterBackgroundService().configure(
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: true,
        isForegroundMode: true,
        // The channel must exist before configure(); it is created by
        // MainActivity alongside the plugin's service declaration.
        notificationChannelId: 'netkeep_keepalive_channel',
        initialNotificationTitle: 'NetKeep Active',
        initialNotificationContent: 'Starting keep-alive monitoring',
        foregroundServiceNotificationId: 1000,
        foregroundServiceTypes: const [AndroidForegroundType.specialUse],
      ),
    );
  }

  static Future<bool> isServiceRunning() async {
    if (!_isAndroid) return false;
    try {
      return await FlutterBackgroundService().isRunning();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> startService({
    required String ispName,
    required String targetUrl,
    required int intervalSeconds,
    bool batterySaver = false,
    bool? showNetworkSpeed,
  }) async {
    if (!_isAndroid) return false;
    await initService();

    final granted = await _ensureNotificationPermission();
    if (!granted) return false;

    final config = KeepAliveConfigData(
      targetUrl: _normalizeTarget(targetUrl),
      ispName: ispName,
      intervalSeconds: intervalSeconds,
      // Battery Saver releases the persistent CPU wake lock, so the ping
      // cadence may be deferred by Android until a natural wake-up.
      batterySaverEnabled: batterySaver,
      showNetworkSpeed: showNetworkSpeed ?? AppPreferences.showNetworkSpeed,
    );

    // Persist before starting: the background isolate reads this to decide
    // whether to resume pinging (and to survive an OS-initiated restart).
    await AppPreferences.setKeepAliveAutoRestart(true);
    await AppPreferences.setKeepAliveConfig(config);

    try {
      final started = await FlutterBackgroundService().startService();
      if (started) {
        // Applies the config to an already-running isolate immediately; a
        // freshly started isolate picks it up from persisted preferences.
        FlutterBackgroundService().invoke('appStart', config.toMap());
        await setWakelock(config.keepWakelock);
      } else {
        await AppPreferences.setKeepAliveAutoRestart(false);
      }
      return started;
    } catch (_) {
      await AppPreferences.setKeepAliveAutoRestart(false);
      return false;
    }
  }

  static Future<bool> stopService() async {
    if (!_isAndroid) return true;
    // Clear the auto-restart flag first so a boot restart does not resume a
    // service the user explicitly stopped. The wake lock is also released so
    // it is not held after the probe loop has gone away.
    await AppPreferences.setKeepAliveAutoRestart(false);
    await setWakelock(false);
    try {
      FlutterBackgroundService().invoke('appStop');
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Updates only the target ISP/URL of the running service without changing
  /// its interval or Battery Saver state.
  static void updateTargetUrl({
    required String ispName,
    required String targetUrl,
  }) {
    updateConfig(ispName: ispName, targetUrl: targetUrl);
  }

  /// Pushes a (partial) configuration change to the running service. Missing
  /// fields keep their current background-side values.
  static void updateConfig({
    String? ispName,
    String? targetUrl,
    int? intervalSeconds,
    bool? batterySaver,
    bool? showNetworkSpeed,
  }) {
    if (!_isAndroid) return;
    final map = <String, dynamic>{};
    if (ispName != null) map['ispName'] = ispName;
    if (targetUrl != null) map['targetUrl'] = _normalizeTarget(targetUrl);
    if (intervalSeconds != null) map['intervalSeconds'] = intervalSeconds;
    if (batterySaver != null) {
      map['batterySaverEnabled'] = batterySaver;
      // Toggling Battery Saver also flips the native partial wake lock so the
      // new behavior applies immediately, without restarting the service.
      setWakelock(!batterySaver);
    }
    if (showNetworkSpeed != null) map['showNetworkSpeed'] = showNetworkSpeed;
    try {
      FlutterBackgroundService().invoke('appUpdateConfig', map);
    } on PlatformException {
      // Service not running / channel unavailable - nothing to update.
    }
  }

  static void updateBatterySaver(bool value) {
    updateConfig(batterySaver: value);
  }

  static void updateShowNetworkSpeed(bool value) {
    updateConfig(showNetworkSpeed: value);
  }

  /// Acquires or releases the partial wake lock backing the keep-alive
  /// service. Held by default so the ping schedule stays exact; Battery Saver
  /// releases it so the CPU may doze between probes and Android can defer the
  /// ping loop until a natural wake-up.
  ///
  /// The channel is handled by the `netkeep_traffic_stats` plugin, which is
  /// attached to *every* Flutter engine (UI and background isolate), so the
  /// lock can be balanced even when the service resumes after a reboot.
  static Future<void> setWakelock(bool enabled) async {
    if (!_isAndroid) return;
    try {
      await _wakelockChannel.invokeMethod<void>('setWakelock', {
        'enabled': enabled,
      });
    } on PlatformException {
      // Native side unavailable - the plugin default (held) applies.
    } on MissingPluginException {
      // ignore
    }
  }

  /// Whether this app is already exempt from the system battery optimization.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_isAndroid) return false;
    try {
      return await _platformChannel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the system battery-optimization settings so the user can exclude
  /// NetKeep from background restrictions (an explicit user choice - the
  /// service never silently disables battery optimization itself).
  static Future<void> openBatteryOptimizationSettings() async {
    if (!_isAndroid) return;
    try {
      await _platformChannel.invokeMethod<void>('openBatteryOptimizationSettings');
    } on PlatformException {
      // Unsupported device/ROM - ignore.
    } on MissingPluginException {
      // ignore
    }
  }

  /// Ensures the Android 13+ notification permission is granted so the
  /// persistent foreground notification is actually visible. Returns false when
  /// the user denies it (the service then refuses to start, matching the
  /// notification-driven UX of the previous native service).
  static Future<bool> _ensureNotificationPermission() async {
    try {
      return await _platformChannel
              .invokeMethod<bool>('ensureNotificationPermission') ??
          true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  static String _normalizeTarget(String targetUrl) {
    final trimmed = targetUrl.trim();
    final envTarget = dotenv.env['TARGET_URL']?.trim();
    return trimmed.isEmpty
        ? (envTarget?.isNotEmpty == true ? envTarget! : defaultKeepAliveTargetUrl)
        : trimmed;
  }
}

/// Background keep-alive probe loop. Runs inside the
/// [flutter_background_service] isolate, fully decoupled from the UI.
///
/// Loop shape (matching the observed Z Pinger behavior):
///   probe  ->  wait `interval`  ->  probe  ->  wait `interval`  ->  ...
/// The wait happens AFTER the current probe completes, so two probes can never
/// overlap and the cadence never tightens when a request is slow.
///
/// Concurrency: a monotonic [_generation] counter invalidates any stale loop
/// whenever the loop is restarted (new target, new interval, stop). Combined
/// with the [_probeInFlight] guard this guarantees at most one probe in flight
/// and zero stale ticks after a config change - so a single authoritative ping
/// loop exists at all times.
///
/// Battery Saver: when enabled the CPU wake lock is released, so Android may
/// suspend the CPU and defer this loop's timer until a natural wake-up. The
/// configured interval is the target cadence but timing is best-effort while
/// the device sleeps.
class KeepAliveEngine {
  KeepAliveEngine(this._service);

  final ServiceInstance _service;
  final PingClient _client = PingClient();

  /// Short connect timeout for fallback probes so an outage does not stretch
  /// the loop cadence beyond the configured interval for too long.
  static const Duration _fallbackTimeout = Duration(seconds: 5);

  KeepAliveConfigData _config = const KeepAliveConfigData(
    targetUrl: defaultKeepAliveTargetUrl,
    ispName: 'Hutch',
  );

  KeepAliveStats _stats = KeepAliveStats.empty;

  final NetworkSpeedMonitor _speedMonitor = NetworkSpeedMonitor();
  Timer? _speedTicker;

  int _generation = 0;
  bool _running = false;
  bool _probeInFlight = false;

  String? _lastNotifTitle;
  String? _lastNotifContent;

  /// Restores the persisted config and decides whether to resume pinging. When
  /// the OS restarted the service (reboot) but the user had stopped it, the
  /// service is shut down immediately instead of resuming.
  Future<void> init() async {
    await AppPreferences.init();
    _config = AppPreferences.keepAliveConfig;
    if (!AppPreferences.keepAliveAutoRestart) {
      await _service.stopSelf();
      return;
    }
    // Balance the wake lock the plugin acquires at service start: Battery
    // Saver releases it so Android may sleep the CPU and defer the loop.
    await KeepAliveManager.setWakelock(_config.keepWakelock);
    _startLoop();
    _emitStatus();
  }

  void applyConfig(Map<String, dynamic>? patch) {
    if (patch == null || patch.isEmpty) return;
    _config = _config.merge(patch);
    _persistConfig();
    _startSpeedTicker();
    // Keep the wake lock in sync even when the change was applied directly to
    // an already-running isolate.
    KeepAliveManager.setWakelock(_config.keepWakelock);
    if (_running) {
      // Restart the loop so a new target/interval takes effect immediately;
      // the generation bump makes any in-flight/stale loop exit after its
      // current probe completes (see [_runLoop]).
      _startLoop();
      _emitStatus();
    }
  }

  Future<void> stop() async {
    if (!_running) {
      _stopSpeedTicker();
      await _speedMonitor.hideSpeedIcon();
      await _service.stopSelf();
      return;
    }
    _running = false;
    _generation++;
    _stopSpeedTicker();
    await _speedMonitor.hideSpeedIcon();
    _emitStatus(running: false);
    _emitProbe(
      'Keep-Alive service stopped',
      success: null,
      latency: 0,
    );
    await _service.stopSelf();
  }

  void _startSpeedTicker() {
    _stopSpeedTicker();
    if (!_running || !_config.showNetworkSpeed) {
      _speedMonitor.hideSpeedIcon();
      return;
    }
    _speedMonitor.reset();
    _speedTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_running || !_config.showNetworkSpeed) {
        _stopSpeedTicker();
        await _speedMonitor.hideSpeedIcon();
        return;
      }
      final speeds = await _speedMonitor.sample();
      if (speeds != null) {
        _emitSpeed(speeds.$1, speeds.$2);
      }
    });
  }

  void _stopSpeedTicker() {
    _speedTicker?.cancel();
    _speedTicker = null;
  }

  /// (Re)starts the probe loop. Bumping the generation invalidates the old
  /// loop so a stale tick can never fire after a restart. Counters reset on
  /// every explicit start.
  void _startLoop() {
    final generation = ++_generation;
    _running = true;
    _stats = KeepAliveStats.empty;
    _startSpeedTicker();
    _runLoop(generation);
  }

  /// The keep-alive loop itself: probe, then wait the full configured interval
  /// AFTER the probe completes, then probe again. Never fires two probes in
  /// parallel, and exits as soon as the generation changes or the service is
  /// stopped.
  Future<void> _runLoop(int generation) async {
    while (_running && generation == _generation) {
      if (_probeInFlight) {
        // A restart happened while a probe was still in flight from the
        // previous loop; wait for it to finish before probing again so probes
        // never overlap.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        continue;
      }
      _probeInFlight = true;
      final PingResult result;
      try {
        result = await _runProbeChain();
      } finally {
        _probeInFlight = false;
      }
      if (!_running || generation != _generation) return;

      _stats = _stats.record(result);
      _emitProbe(
        _formatProbeMessage(result),
        success: result.ok,
        latency: result.ok ? result.rttMs : 0,
      );
      await _updateNotification(result);
      if (!_running || generation != _generation) return;

      final intervalSeconds = _config.intervalSeconds.clamp(1, 3600).toInt();
      await Future<void>.delayed(Duration(seconds: intervalSeconds));
    }
  }

  /// Probes the primary target; when it is unreachable, checks the fallback
  /// targets once so an ISP-target outage is not reported as a full connection
  /// loss.
  Future<PingResult> _runProbeChain() async {
    final primary = await _client.probe(_config.targetUrl);
    if (primary.ok || primary.errorKind == PingErrorKind.invalidUrl) {
      return primary;
    }
    for (final fallback in keepAliveFallbackTargets) {
      final result = await _client.probe(fallback, timeout: _fallbackTimeout);
      if (result.ok) return result.asFallback();
    }
    return primary;
  }

  String _formatProbeMessage(PingResult result) {
    if (result.ok) {
      return '${result.rttMs}ms | Status: ${result.statusCode}';
    }
    switch (result.errorKind) {
      case PingErrorKind.timeout:
        return '${result.rttMs}ms | Status: Timeout';
      case PingErrorKind.invalidUrl:
        return 'Status: Invalid URL';
      case PingErrorKind.dns:
      case PingErrorKind.network:
      case PingErrorKind.none:
        return 'Status: Network Down';
    }
  }

  /// Keeps the foreground service notification text intentional: "NetKeep
  /// Active / Keeping connection alive" while the connection is up, and
  /// "Connection Lost" on a transport-level failure. Only re-issued when the
  /// text actually changes, so the status bar does not flicker.
  ///
  /// Updates go through the unified notification builder
  /// (`netkeep/speed_notification` channel) instead of the background plugin's
  /// `setForegroundNotificationInfo()`: that call re-posts notification 1000
  /// with the plugin's own default builder config (PRIVATE visibility, no
  /// group), which conflicts with the unified builder's PUBLIC/group/priority
  /// config and is the dual `notify(1000)` owner being eliminated. The plugin
  /// only posts 1000 once at service start, after which this single builder
  /// owns every live update.
  Future<void> _updateNotification(PingResult result) async {
    if (_service is! AndroidServiceInstance) return;
    final title = 'NetKeep Active';
    final content = result.ok
        ? 'Keeping connection alive · ${result.rttMs}ms'
        : 'Connection Lost';
    if (title == _lastNotifTitle && content == _lastNotifContent) return;
    _lastNotifTitle = title;
    _lastNotifContent = content;
    try {
      await _speedMonitor.updateContent(title: title, content: content);
    } catch (_) {
      // Notification text update is best-effort.
    }
  }

  void _emitStatus({bool? running}) {
    _service.invoke('keepAliveEvent', <String, dynamic>{
      'type': 'status',
      'running': running ?? _running,
      'intervalSeconds': _config.intervalSeconds,
      'batterySaverEnabled': _config.batterySaverEnabled,
      'showNetworkSpeed': _config.showNetworkSpeed,
      ..._stats.toMap(),
    });
  }

  void _emitProbe(
    String message, {
    required bool? success,
    required int? latency,
  }) {
    _service.invoke('keepAliveEvent', <String, dynamic>{
      'type': 'probe',
      'time': _timestampIso(),
      'message': message,
      'success': success ?? false,
      'latency': latency ?? 0,
      ..._stats.toMap(),
    });
  }

  void _emitSpeed(int downloadBps, int uploadBps) {
    _service.invoke('keepAliveEvent', <String, dynamic>{
      'type': 'speed',
      'downloadSpeed': downloadBps,
      'uploadSpeed': uploadBps,
    });
  }

  Future<void> _persistConfig() => AppPreferences.setKeepAliveConfig(_config);

  String _timestampIso() => DateTime.now().toIso8601String();
}
