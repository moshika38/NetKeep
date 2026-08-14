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
import 'package:netkeep/services/speed.heartbeat.dart';

/// Background-isolate entry point, invoked by [flutter_background_service]
/// whenever the Android foreground service is (re)started - including the
/// automatic restart after a device reboot. It owns the ping loop entirely in
/// Dart, so the service keeps probing while the UI is closed.
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final engine = KeepAliveEngine(service);
  await engine.init();

  service.on('appStart').listen(engine.handleAppStart);
  service.on('appUpdateConfig').listen(engine.applyConfig);
  service.on('appStop').listen((_) => engine.stop());
}

/// iOS background-fetch counterpart. Kept minimal; keep-alive is Android-only.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

enum KeepAliveEventType { probe, status }

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
      consecutiveFailures: (map['consecutiveFailures'] as num?)?.toInt() ?? 0,
      totalFailures: (map['totalFailures'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A single event pushed from the background isolate over the plugin stream.
/// `probe` events carry a formatted console line plus the transport result and
/// latency; `status` events carry the current running state (used to reconnect
/// the UI after the activity is recreated or the app resumes). The live speed
/// readout is self-contained in the background isolate and never surfaces in
/// the UI.
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
    this.stats,
  });

  factory KeepAliveEvent.fromMap(Map<dynamic, dynamic> map) {
    return KeepAliveEvent(
      type: switch (map['type']) {
        'status' => KeepAliveEventType.status,
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

  static const MethodChannel _platformChannel = MethodChannel(
    'netkeep/platform',
  );
  static const MethodChannel _wakelockChannel = MethodChannel(
    'netkeep/wakelock',
  );

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
      final isRunning = await isServiceRunning();
      if (isRunning) {
        FlutterBackgroundService().invoke('appStart', config.toMap());
        return true;
      }
      final started = await FlutterBackgroundService().startService();
      if (started) {
        FlutterBackgroundService().invoke('appStart', config.toMap());
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
    // service the user explicitly stopped. The background isolate decides
    // whether to keep running (network-speed-only mode) or tear everything
    // down, and balances the wake lock itself.
    await AppPreferences.setKeepAliveAutoRestart(false);
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

  /// Toggles the network-speed heartbeat independently of the Ping Service.
  ///
  /// When the service is already running (ping and/or speed) the change is
  /// pushed straight into the background isolate. When nothing is running and
  /// the user enables the speed indicator, the background service is started
  /// for speed-only mode; the background isolate keeps it alive as long as the
  /// toggle stays on, regardless of the ping loop state.
  static Future<bool> setShowNetworkSpeedEnabled(bool value) async {
    if (!_isAndroid) return true;
    await AppPreferences.setShowNetworkSpeed(value);
    final running = await isServiceRunning();
    if (running) {
      updateConfig(showNetworkSpeed: value);
    } else if (value) {
      await startSpeedIndicator();
    }
    return true;
  }

  /// Starts the background service for the network-speed indicator only. The
  /// keep-alive ping loop stays stopped, so unlike [startService] this does
  /// NOT set the boot auto-restart flag.
  static Future<bool> startSpeedIndicator() async {
    if (!_isAndroid) return false;
    await initService();

    final granted = await _ensureNotificationPermission();
    if (!granted) return false;

    final persisted = AppPreferences.keepAliveConfig;
    final config = KeepAliveConfigData(
      targetUrl: persisted.targetUrl,
      ispName: persisted.ispName,
      intervalSeconds: persisted.intervalSeconds,
      batterySaverEnabled: AppPreferences.batterySaverEnabled,
      showNetworkSpeed: true,
    );
    await AppPreferences.setKeepAliveConfig(config);

    try {
      final started = await FlutterBackgroundService().startService();
      if (started) {
        FlutterBackgroundService().invoke('appStart', config.toMap());
      }
      return started;
    } catch (_) {
      return false;
    }
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
      return await _platformChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
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
      await _platformChannel.invokeMethod<void>(
        'openBatteryOptimizationSettings',
      );
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
      return await _platformChannel.invokeMethod<bool>(
            'ensureNotificationPermission',
          ) ??
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
        ? (envTarget?.isNotEmpty == true
              ? envTarget!
              : defaultKeepAliveTargetUrl)
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
/// The network-speed heartbeat ([SpeedHeartbeat]) is owned separately: it
/// starts/stops with the "Display Network Speed" toggle and keeps running
/// (driving the status-bar speed glyph) even when the probe loop is stopped -
/// the two loops share this isolate but never gate each other.
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

  /// Fallback probes use the same 10-second timeout as the primary probe so an
  /// ISP-target outage is not reported as a full connection loss while still
  /// giving each fallback target a fair chance to respond.
  static const Duration _fallbackTimeout = Duration(seconds: 10);

  KeepAliveConfigData _config = const KeepAliveConfigData(
    targetUrl: defaultKeepAliveTargetUrl,
    ispName: 'Hutch',
  );

  KeepAliveStats _stats = KeepAliveStats.empty;

  final NetworkSpeedMonitor _speedMonitor = NetworkSpeedMonitor();
  SpeedHeartbeat? _speedHeartbeat;

  int _generation = 0;
  bool _pingRunning = false;
  bool _probeInFlight = false;

  String? _lastNotifTitle;
  String? _lastNotifContent;

  /// Whether the service isolate has anything to do: the ping loop, the
  /// network-speed heartbeat, or both. When only the speed heartbeat is active
  /// the service keeps running so the status-bar indicator stays live even
  /// though no probes are being fired.
  bool get _shouldHoldWakelock =>
      (_pingRunning || _speedHeartbeat != null) && _config.keepWakelock;

  /// Restores the persisted config and decides what to run. The ping loop
  /// resumes only when the user had left it running (boot auto-restart). The
  /// network-speed heartbeat is decoupled: it resumes whenever the toggle was
  /// left ON, regardless of the ping loop state.
  Future<void> init() async {
    await AppPreferences.init();
    _config = AppPreferences.keepAliveConfig;
    final pingEnabled = AppPreferences.keepAliveAutoRestart;
    final speedEnabled = _config.showNetworkSpeed;
    if (!pingEnabled && !speedEnabled) {
      await _service.stopSelf();
      return;
    }
    if (speedEnabled) {
      _startSpeedHeartbeat();
      if (!pingEnabled) {
        // Speed-only resume: keep the notification text honest so it does not
        // claim probes are running.
        _speedMonitor.updateContent(
          title: 'NetKeep Active',
          content: 'Network speed active',
        );
      }
    }
    if (pingEnabled) {
      _startPingLoop();
    }
    await KeepAliveManager.setWakelock(_shouldHoldWakelock);
    _emitStatus();
  }

  void handleAppStart(Map<String, dynamic>? patch) {
    if (patch != null && patch.isNotEmpty) {
      _config = _config.merge(patch);
      _persistConfig();
    }
    _syncSpeedHeartbeat();
    _startPingLoop();
    KeepAliveManager.setWakelock(_shouldHoldWakelock);
    _emitStatus();
  }

  void applyConfig(Map<String, dynamic>? patch) {
    if (patch == null || patch.isEmpty) return;
    _config = _config.merge(patch);
    _persistConfig();
    _syncSpeedHeartbeat();
    KeepAliveManager.setWakelock(_shouldHoldWakelock);
    if (_pingRunning) {
      if (_patchAffectsPing(patch)) {
        // Restart the loop so a new target/interval takes effect immediately;
        // the generation bump makes any in-flight/stale loop exit after its
        // current probe completes (see [_runLoop]).
        _startPingLoop();
      }
      _emitStatus();
    } else if (!_config.showNetworkSpeed) {
      // Nothing left for this isolate to do (speed was turned off with no
      // ping loop to keep alive).
      _stopSpeedHeartbeat().then((_) async {
        await KeepAliveManager.setWakelock(false);
        await _service.stopSelf();
      });
    } else {
      _emitStatus();
    }
  }

  bool _patchAffectsPing(Map<dynamic, dynamic> patch) {
    return patch.containsKey('targetUrl') ||
        patch.containsKey('ispName') ||
        patch.containsKey('intervalSeconds') ||
        patch.containsKey('batterySaverEnabled');
  }

  Future<void> stop() async {
    _pingRunning = false;
    _generation++;
    _emitStatus(running: false);
    if (_config.showNetworkSpeed) {
      _emitProbe('Keep-Alive ping service stopped', success: null, latency: 0);
      try {
        await _speedMonitor.updateContent(
          title: 'NetKeep Active',
          content: 'Network speed active',
        );
      } catch (_) {}
      await KeepAliveManager.setWakelock(_shouldHoldWakelock);
    } else {
      await _stopSpeedHeartbeat();
      _emitProbe('Keep-Alive service stopped', success: null, latency: 0);
      await KeepAliveManager.setWakelock(false);
      await _service.stopSelf();
    }
  }

  void _startSpeedHeartbeat() {
    final existing = _speedHeartbeat;
    if (existing != null) {
      // Re-point the heartbeat at a new primary target without restarting the
      // ping loop; the toggle state itself is unchanged.
      if (existing.targetUrl == _config.targetUrl) return;
      existing.stop();
    }
    _speedHeartbeat = SpeedHeartbeat(targetUrl: _config.targetUrl)..start();
  }

  Future<void> _stopSpeedHeartbeat() async {
    final heartbeat = _speedHeartbeat;
    _speedHeartbeat = null;
    if (heartbeat != null) {
      await heartbeat.stop();
    } else {
      await _speedMonitor.hideSpeedIcon();
    }
  }

  /// Starts or stops the network-speed heartbeat so it always mirrors the
  /// "Display Network Speed" toggle, independent of the ping loop.
  void _syncSpeedHeartbeat() {
    if (_config.showNetworkSpeed) {
      _startSpeedHeartbeat();
    } else {
      _stopSpeedHeartbeat();
    }
  }

  /// (Re)starts the probe loop. Bumping the generation invalidates the old
  /// loop so a stale tick can never fire after a restart. Counters reset on
  /// every explicit start. The network-speed heartbeat is deliberately NOT
  /// touched here - it is owned by the speed toggle, not the ping loop.
  void _startPingLoop() {
    final generation = ++_generation;
    _pingRunning = true;
    _stats = KeepAliveStats.empty;
    _runLoop(generation);
  }

  /// The keep-alive loop itself: probe, then wait the full configured interval
  /// AFTER the probe completes, then probe again. Never fires two probes in
  /// parallel, and exits as soon as the generation changes or the service is
  /// stopped.
  Future<void> _runLoop(int generation) async {
    while (_pingRunning && generation == _generation) {
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
      if (!_pingRunning || generation != _generation) return;

      _stats = _stats.record(result);
      _emitProbe(
        _formatProbeMessage(result),
        success: result.ok,
        latency: result.ok ? result.rttMs : 0,
      );
      await _updateNotification(result);
      if (!_pingRunning || generation != _generation) return;

      final intervalSeconds = _config.intervalSeconds.clamp(1, 3600).toInt();
      await Future<void>.delayed(_nextDelay(intervalSeconds));
    }
  }

  /// Computes the wait between probes. While the connection is healthy this is
  /// simply the configured interval. During consecutive network failures an
  /// exponential backoff kicks in: every failed probe doubles the wait (from
  /// the configured interval) so an outage does not hammer the targets at full
  /// cadence, capped at `interval * 4`. The first successful response resets
  /// the counter, so [KeepAliveStats.record] drops `consecutiveFailures` back
  /// to zero and the loop returns to the normal interval.
  Duration _nextDelay(int intervalSeconds) {
    final capSeconds = intervalSeconds * 4;
    var backoffSeconds = intervalSeconds;
    for (
      var i = 1;
      i < _stats.consecutiveFailures && backoffSeconds < capSeconds;
      i++
    ) {
      backoffSeconds *= 2;
    }
    if (backoffSeconds > capSeconds) backoffSeconds = capSeconds;
    return Duration(seconds: backoffSeconds);
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
      return '${result.rttMs}ms | ${_statusLabel(result.statusCode)}';
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

  /// Maps an HTTP status code to a human-readable console label so standard
  /// 200 OK responses and Anti-403 pass responses (portal redirects / explicit
  /// forbiddens from the ISP) are clearly distinguishable in the log.
  String _statusLabel(int? status) {
    switch (status) {
      case 200:
        return 'Status: 200 OK';
      case 301:
      case 302:
        return 'Status: $status Redirect (Anti-403 pass)';
      case 403:
        return 'Status: 403 Forbidden (Anti-403 pass)';
      default:
        return 'Status: $status';
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
      'running': running ?? _pingRunning,
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

  Future<void> _persistConfig() => AppPreferences.setKeepAliveConfig(_config);

  String _timestampIso() => DateTime.now().toIso8601String();
}
