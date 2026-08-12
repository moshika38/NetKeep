/// Primary target pinged by the keep-alive loop. The observed Z Pinger
/// default is https://www.google.com; an existing .env `TARGET_URL` (e.g.
/// https://oneapp.hutch.lk) or the selected ISP URL takes precedence at
/// runtime, so Hutch stays the effective target while it is configured.
const String defaultKeepAliveTargetUrl = 'https://www.google.com';

/// Interval (seconds) used when no explicit configuration is supplied.
const int defaultKeepAliveIntervalSeconds = 5;

/// The selectable ping intervals offered by the Home Screen.
const List<int> keepAliveIntervals = [5, 10, 15, 30, 60];

/// Secondary targets probed when the primary target is unreachable so an ISP
/// target outage can be told apart from a genuine connection loss.
const List<String> keepAliveFallbackTargets = [
  'https://www.google.com',
  'https://selfcare.dialog.lk',
  'https://mas.mobitel.lk',
];

/// Immutable snapshot of the keep-alive service configuration.
///
/// There is no "mode" concept: [intervalSeconds] directly controls the ping
/// cadence and [batterySaverEnabled] decides whether the CPU wake lock is held.
/// The same value is exchanged between the UI isolate and the background
/// isolate and persisted to [SharedPreferences] so an OS-initiated restart
/// (after reboot) can resume the exact same target/interval without Flutter.
class KeepAliveConfigData {
  final String targetUrl;
  final String ispName;
  final int intervalSeconds;
  final bool batterySaverEnabled;
  final bool showNetworkSpeed;

  const KeepAliveConfigData({
    required this.targetUrl,
    required this.ispName,
    this.intervalSeconds = defaultKeepAliveIntervalSeconds,
    this.batterySaverEnabled = false,
    this.showNetworkSpeed = false,
  });

  /// Battery Saver releases the persistent CPU wake lock, so Android may
  /// sleep the CPU and defer the ping loop until a natural wake-up.
  bool get keepWakelock => !batterySaverEnabled;

  factory KeepAliveConfigData.fromMap(Map<dynamic, dynamic> map) {
    final target = map['targetUrl'] as String?;
    final isp = map['ispName'] as String?;
    return KeepAliveConfigData(
      targetUrl: target?.trim().isNotEmpty == true
          ? target!.trim()
          : defaultKeepAliveTargetUrl,
      ispName: isp?.trim().isNotEmpty == true ? isp! : 'Hutch',
      intervalSeconds: _clampInterval(
        (map['intervalSeconds'] as num?)?.toInt() ??
            defaultKeepAliveIntervalSeconds,
      ),
      batterySaverEnabled: map['batterySaverEnabled'] as bool? ?? false,
      showNetworkSpeed: map['showNetworkSpeed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'targetUrl': targetUrl,
    'ispName': ispName,
    'intervalSeconds': intervalSeconds,
    'batterySaverEnabled': batterySaverEnabled,
    'showNetworkSpeed': showNetworkSpeed,
  };

  /// Merges a partial patch over this config; every field absent from the
  /// patch keeps its current value.
  KeepAliveConfigData merge(Map<dynamic, dynamic> patch) {
    final target = patch['targetUrl'] as String?;
    final isp = patch['ispName'] as String?;
    return KeepAliveConfigData(
      targetUrl: target?.trim().isNotEmpty == true
          ? target!.trim()
          : targetUrl,
      ispName: isp?.trim().isNotEmpty == true ? isp! : ispName,
      intervalSeconds: patch['intervalSeconds'] is num
          ? _clampInterval((patch['intervalSeconds'] as num).toInt())
          : intervalSeconds,
      batterySaverEnabled:
          patch['batterySaverEnabled'] as bool? ?? batterySaverEnabled,
      showNetworkSpeed: patch['showNetworkSpeed'] as bool? ?? showNetworkSpeed,
    );
  }

  static int _clampInterval(int seconds) => seconds.clamp(1, 3600).toInt();
}
