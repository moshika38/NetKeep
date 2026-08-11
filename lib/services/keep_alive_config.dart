/// Primary target pinged by the keep-alive loop. The observed Z Pinger
/// default is https://www.google.com; an existing .env `TARGET_URL` (e.g.
/// https://oneapp.hutch.lk) or the selected ISP URL takes precedence at
/// runtime, so Hutch stays the effective target while it is configured.
const String defaultKeepAliveTargetUrl = 'https://www.google.com';

/// Interval (seconds) used when no explicit configuration is supplied.
const int defaultKeepAliveIntervalSeconds = 15;

/// Secondary targets probed when the primary target is unreachable so an ISP
/// target outage can be told apart from a genuine connection loss.
const List<String> keepAliveFallbackTargets = [
  'https://www.google.com',
  'https://selfcare.dialog.lk',
  'https://mas.mobitel.lk',
];

/// Immutable snapshot of the keep-alive service configuration.
///
/// The same value is exchanged between the UI isolate and the background
/// isolate and persisted to [SharedPreferences] so an OS-initiated restart
/// (after reboot) can resume the exact same target/mode without Flutter.
class KeepAliveConfigData {
  final String targetUrl;
  final String ispName;
  final String modeName;
  final int intervalSeconds;
  final bool showNetworkSpeed;
  final bool keepWakelock;

  const KeepAliveConfigData({
    required this.targetUrl,
    required this.ispName,
    this.modeName = 'Normal Mode',
    this.intervalSeconds = defaultKeepAliveIntervalSeconds,
    this.showNetworkSpeed = true,
    this.keepWakelock = true,
  });

  factory KeepAliveConfigData.fromMap(Map<dynamic, dynamic> map) {
    final target = map['targetUrl'] as String?;
    final isp = map['ispName'] as String?;
    final mode = map['modeName'] as String?;
    return KeepAliveConfigData(
      targetUrl: target?.trim().isNotEmpty == true
          ? target!.trim()
          : defaultKeepAliveTargetUrl,
      ispName: isp?.trim().isNotEmpty == true ? isp! : 'Hutch',
      modeName: mode?.trim().isNotEmpty == true ? mode! : 'Normal Mode',
      intervalSeconds: _clampInterval(
        (map['intervalSeconds'] as num?)?.toInt() ??
            defaultKeepAliveIntervalSeconds,
      ),
      showNetworkSpeed: map['showNetworkSpeed'] as bool? ?? true,
      keepWakelock: map['keepWakelock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'targetUrl': targetUrl,
    'ispName': ispName,
    'modeName': modeName,
    'intervalSeconds': intervalSeconds,
    'showNetworkSpeed': showNetworkSpeed,
    'keepWakelock': keepWakelock,
  };

  /// Merges a partial patch over this config; every field absent from the
  /// patch keeps its current value.
  KeepAliveConfigData merge(Map<dynamic, dynamic> patch) {
    final target = patch['targetUrl'] as String?;
    final isp = patch['ispName'] as String?;
    final mode = patch['modeName'] as String?;
    return KeepAliveConfigData(
      targetUrl: target?.trim().isNotEmpty == true
          ? target!.trim()
          : targetUrl,
      ispName: isp?.trim().isNotEmpty == true ? isp! : ispName,
      modeName: mode?.trim().isNotEmpty == true ? mode! : modeName,
      intervalSeconds: patch['intervalSeconds'] is num
          ? _clampInterval((patch['intervalSeconds'] as num).toInt())
          : intervalSeconds,
      showNetworkSpeed: patch['showNetworkSpeed'] as bool? ?? showNetworkSpeed,
      keepWakelock: patch['keepWakelock'] as bool? ?? keepWakelock,
    );
  }

  static int _clampInterval(int seconds) => seconds.clamp(1, 3600).toInt();
}
