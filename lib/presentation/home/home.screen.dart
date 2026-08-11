import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/services/keep_alive_service.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
import 'package:netkeep/widgets/home_widgets/isp.dropdown.dart';
import 'package:netkeep/widgets/home_widgets/live.console.dart';
import 'package:netkeep/widgets/home_widgets/profile.dropdown.dart';
import 'package:netkeep/widgets/section.header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _activeProfileIndex = 0;
  int _customIntervalSeconds = 15;
  bool isServiceRunning = false;
  late String _selectedIspUrl;
  late IspConfig _selectedIsp;
  final List<(String, String)> _logs = [];
  StreamSubscription<KeepAliveEvent>? _eventSubscription;

  /// Newest entries first; the console keeps at most this many lines.
  static const int _maxLogEntries = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIspUrl = AppPreferences.selectedIspUrl;
    _selectedIsp = supportedIsps.firstWhere(
      (isp) => isp.url == _selectedIspUrl,
      orElse: () => supportedIsps.first,
    );
    _subscribeToEvents();
    _checkServiceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    super.dispose();
  }

  // Reconnects the UI to the (possibly already running) native service after
  // the app is resumed or the activity is recreated.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
    }
  }

  void _subscribeToEvents() {
    _eventSubscription ??= KeepAliveManager.events.listen(_onServiceEvent);
  }

  void _onServiceEvent(KeepAliveEvent event) {
    if (!mounted) return;
    if (event.type == KeepAliveEventType.status) {
      setState(() {
        isServiceRunning = event.running ?? isServiceRunning;
      });
      return;
    }
    final message = event.message;
    final time = event.time;
    if (message != null && time != null) {
      setState(() {
        _logs.add((_formatConsoleTime(time), message));
        // The console renders newest-first, so dropping from the front keeps
        // the most recent [_maxLogEntries] lines.
        if (_logs.length > _maxLogEntries) {
          _logs.removeRange(0, _logs.length - _maxLogEntries);
        }
      });
    }
  }

  String _formatConsoleTime(String iso) {
    try {
      final parsed = DateTime.parse(iso).toLocal();
      String two(int value) => value.toString().padLeft(2, '0');
      return '${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _checkServiceStatus() async {
    final running = await KeepAliveManager.isServiceRunning();
    if (!mounted) return;
    setState(() {
      isServiceRunning = running;
    });
  }

  void _onIspChanged(IspConfig isp) {
    setState(() {
      _selectedIsp = isp;
      _selectedIspUrl = isp.url;
    });
    AppPreferences.setSelectedIspUrl(isp.url);
    KeepAliveManager.updateTargetUrl(
      ispName: isp.name,
      targetUrl: isp.url,
    );
  }

  // Toggle the keep-alive state and start/stop the native foreground service.
  Future<void> _toggleKeepAlive() async {
    if (isServiceRunning) {
      await KeepAliveManager.stopService();
      if (!mounted) return;
      if (AppPreferences.autoClearConsole) {
        _logs.clear();
      }
    } else {
      final (modeName, intervalSeconds) = _activeModeInfo;
      final started = await KeepAliveManager.startService(
        ispName: _selectedIsp.name,
        targetUrl: _selectedIsp.url,
        modeName: modeName,
        intervalSeconds: intervalSeconds,
      );
      if (!mounted) return;
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is required to run the keep-alive service.',
            ),
          ),
        );
        return;
      }
      _logs.clear();
    }
    await _checkServiceStatus();
  }

  // The currently selected power profile: (display name, ping interval).
  // Intervals follow the observed Z Pinger set: 5/10/15/30/60 seconds with a
  // 15s default.
  (String, int) get _activeModeInfo {
    switch (_activeProfileIndex) {
      case 0:
        return ('Normal Mode', 15);
      case 1:
        return ('Saver Mode', 60);
      case 2:
        return ('Custom (${_customIntervalSeconds}s)', _customIntervalSeconds);
      default:
        return ('Normal Mode', 15);
    }
  }

  // Pushes the currently selected profile (mode + interval) to the running
  // background keep-alive isolate so its probe cadence matches the UI.
  void _syncBackgroundMode() {
    if (!isServiceRunning) return;
    final (modeName, intervalSeconds) = _activeModeInfo;
    KeepAliveManager.updateConfig(
      ispName: _selectedIsp.name,
      targetUrl: _selectedIsp.url,
      modeName: modeName,
      intervalSeconds: intervalSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NetKeepAppBar(
        title: 'NetKeep',
        actions: [
          IspDropdown(
            selectedUrl: _selectedIspUrl,
            onChanged: _onIspChanged,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'NetKeep Status',
            subtitle: 'Connection control center',
          ),
          const SizedBox(height: 12),
          _StatusCard(running: isServiceRunning),
          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: _toggleKeepAlive,
              icon: Icon(isServiceRunning ? Icons.stop : Icons.power_settings_new),
              label: Text(
                isServiceRunning ? 'Stop Keep-Alive' : 'Start Keep-Alive',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isServiceRunning
                    ? AppColors.secondaryColor
                    : AppColors.primaryColor,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Keep-Alive Profile',
            subtitle: 'Choose a power profile',
          ),
          const SizedBox(height: 12),
          ProfileDropdown(
            selectedIndex: _activeProfileIndex,
            onChanged: (index) => setState(() {
              _activeProfileIndex = index;
              _syncBackgroundMode();
            }),
            customIntervalSeconds: _customIntervalSeconds,
            onCustomIntervalChanged: (value) => setState(() {
              _customIntervalSeconds = value;
              _syncBackgroundMode();
            }),
          ),
          const SizedBox(height: 28),
          LiveConsoleWidget(
            logs: _logs,
            running: isServiceRunning,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool running;
  const _StatusCard({required this.running});

  @override
  Widget build(BuildContext context) {
    final color = running ? AppColors.secondaryColor : AppColors.tertiaryColor;
    return SizedBox(
      height: 120,
      child: Card(
        margin: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Center(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  running ? Icons.wifi : Icons.wifi_off,
                  color: color,
                  size: 22,
                ),
              ),
              title: Text(
                running ? 'SYSTEM ONLINE' : 'SYSTEM OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              subtitle: Text(
                running ? 'Keep-Alive is active' : 'Connection is idle',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      running ? 'ACTIVE' : 'IDLE',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
