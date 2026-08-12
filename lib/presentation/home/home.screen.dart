import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/services/keep_alive_config.dart';
import 'package:netkeep/services/keep_alive_service.dart';
import 'package:netkeep/services/network.speed.monitor.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
import 'package:netkeep/widgets/home_widgets/isp.dropdown.dart';
import 'package:netkeep/widgets/home_widgets/live.console.dart';
import 'package:netkeep/widgets/section.header.dart';

/// Home screen: single keep-alive workflow.
///
/// No profiles/modes anymore. The user configures ISP, ping interval,
/// Battery Saver and speed display directly, then toggles the service.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isServiceRunning = false;
  int _intervalSeconds = AppPreferences.pingIntervalSeconds;
  bool _batterySaver = AppPreferences.batterySaverEnabled;
  bool _showNetworkSpeed = AppPreferences.showNetworkSpeed;
  int? _downloadBps;
  int? _uploadBps;
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
    _selectedIsp = _resolveIsp(_selectedIspUrl);
    _subscribeToEvents();
    _checkServiceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
    }
  }

  IspConfig _resolveIsp(String url) => supportedIsps.firstWhere(
        (isp) => isp.url == url,
        orElse: () => supportedIsps.first,
      );

  // Reconnects the UI to the background isolate's stream. The stream is a
  // persistent broadcast stream, so re-subscribing is safe and cheap.
  void _subscribeToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = KeepAliveManager.events.listen(_onServiceEvent);
  }

  void _onServiceEvent(KeepAliveEvent event) {
    switch (event.type) {
      case KeepAliveEventType.status:
        _handleStatusEvent(event);
        break;
      case KeepAliveEventType.probe:
        _handleProbeEvent(event);
        break;
      case KeepAliveEventType.speed:
        _handleSpeedEvent(event);
        break;
    }
  }

  void _handleStatusEvent(KeepAliveEvent event) {
    if (event.running == null) return;
    final wasRunning = isServiceRunning;
    isServiceRunning = event.running!;
    if (mounted) {
      setState(() {
        if (isServiceRunning != wasRunning) {
          _logs.insert(0, (
            _formatTime(event.time, DateTime.now()),
            isServiceRunning ? 'Service started' : 'Service stopped',
          ));
        }
      });
    }
    final statLine = _getStatsLine(event.stats);
    if (statLine != null) _addLog(statLine);
  }

  void _handleProbeEvent(KeepAliveEvent event) {
    _addLog(
      '${(event.message ?? '').replaceAll('Status: ', '')} '
      '| ${_formatTime(event.time, DateTime.now())}',
    );
  }

  void _handleSpeedEvent(KeepAliveEvent event) {
    if (!_showNetworkSpeed || event.downloadSpeed == null) return;
    setState(() {
      _downloadBps = event.downloadSpeed;
      _uploadBps = event.uploadSpeed;
    });
  }

  String? _getStatsLine(KeepAliveStats? stats) {
    if (stats == null) return null;
    final failures = stats.consecutiveFailures;
    if (failures > 0) {
      final drop = failures == 1 ? 'drop' : 'drops';
      return 'Stats: ${stats.totalPings} pings, ${stats.successfulPings} ok, '
          '${stats.failedPings} fail, avg ${stats.averageLatencyMs}ms · '
          '$failures consecutive $drop';
    }
    return 'Stats: ${stats.totalPings} pings, ${stats.successfulPings} ok, '
        'avg ${stats.averageLatencyMs}ms';
  }

  void _addLog(String message) {
    if (_logs.length >= _maxLogEntries) {
      _logs.removeLast();
    }
    _logs.insert(0, (_formatTime(null, DateTime.now()), message));
    if (mounted) setState(() {});
  }

  String _formatTime(String? isoTime, DateTime fallback) {
    final DateTime time;
    if (isoTime != null) {
      time = DateTime.tryParse(isoTime) ?? fallback;
    } else {
      time = fallback;
    }
    return '[${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}]';
  }

  Future<void> _checkServiceStatus() async {
    final running = await KeepAliveManager.isServiceRunning();
    if (mounted) setState(() => isServiceRunning = running);
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> _toggleService() async {
    if (isServiceRunning) {
      setState(() {
        isServiceRunning = false;
        _downloadBps = null;
        _uploadBps = null;
      });
      await KeepAliveManager.stopService();
      return;
    }
    final started = await KeepAliveManager.startService(
      ispName: _selectedIsp.name,
      targetUrl: _selectedIsp.url,
      intervalSeconds: _intervalSeconds,
      batterySaver: _batterySaver,
      showNetworkSpeed: _showNetworkSpeed,
    );
    if (started && mounted) {
      setState(() => isServiceRunning = true);
    }
  }

  Future<void> _onIspChanged(IspConfig isp) async {
    if (isp.url == _selectedIspUrl) return;
    setState(() {
      _selectedIspUrl = isp.url;
      _selectedIsp = isp;
    });
    await AppPreferences.setSelectedIspUrl(isp.url);
    if (isServiceRunning) {
      KeepAliveManager.updateTargetUrl(ispName: isp.name, targetUrl: isp.url);
    }
  }

  Future<void> _onIntervalChanged(int seconds) async {
    if (seconds == _intervalSeconds) return;
    setState(() => _intervalSeconds = seconds);
    await AppPreferences.setPingIntervalSeconds(seconds);
    if (isServiceRunning) {
      KeepAliveManager.updateConfig(intervalSeconds: seconds);
    }
  }

  Future<void> _onBatterySaverChanged(bool value) async {
    setState(() => _batterySaver = value);
    await AppPreferences.setBatterySaverEnabled(value);
    if (isServiceRunning) {
      KeepAliveManager.updateBatterySaver(value);
    }
  }

  Future<void> _onShowNetworkSpeedChanged(bool value) async {
    setState(() {
      _showNetworkSpeed = value;
      if (!value) {
        _downloadBps = null;
        _uploadBps = null;
      }
    });
    await AppPreferences.setShowNetworkSpeed(value);
    if (isServiceRunning) {
      KeepAliveManager.updateShowNetworkSpeed(value);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const NetKeepAppBar(title: 'NetKeep'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 12),
                  _buildServiceButton(),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Connection Target',
                    subtitle: 'Choose the ISP to keep alive',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IspDropdown(
                      selectedUrl: _selectedIspUrl,
                      onChanged: _onIspChanged,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Ping Interval',
                    subtitle: 'How often the service probes the network',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildIntervalSelector(),
                  ),
                  const SizedBox(height: 20),
                  _buildBatterySaverCard(),
                  const SizedBox(height: 12),
                  _buildSpeedToggleCard(),
                  if (_showNetworkSpeed && isServiceRunning) ...[
                    const SizedBox(height: 20),
                    _buildSpeedCard(),
                  ],
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Ping Information',
                    subtitle: 'Live probe output',
                  ),
                  const SizedBox(height: 12),
                  LiveConsoleWidget(logs: _logs, running: isServiceRunning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isServiceRunning
                  ? AppColors.secondaryColor
                  : AppColors.tertiaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isServiceRunning ? 'Service ON' : 'Service OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isServiceRunning
                      ? '${_selectedIsp.name} · every $_intervalSeconds seconds'
                      : 'Start the service to begin keep-alive',
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton() {
    final color = isServiceRunning
        ? AppColors.tertiaryColor
        : AppColors.primaryColor;
    return Material(
      color: color,
      child: InkWell(
        onTap: _toggleService,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            isServiceRunning ? 'STOP SERVICE' : 'START SERVICE',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return InkWell(
      onTap: _showIntervalPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 16,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Every ${_intervalSeconds}s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textColor),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBgColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ping Interval',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...keepAliveIntervals.map(
              (seconds) => ListTile(
                dense: true,
                title: Text(
                  'Every ${seconds}s',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                trailing: seconds == _intervalSeconds
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primaryColor,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _onIntervalChanged(seconds);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterySaverCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: SwitchListTile(
        value: _batterySaver,
        onChanged: _onBatterySaverChanged,
        secondary: const Icon(
          Icons.battery_saver_outlined,
          color: AppColors.secondaryColor,
        ),
        title: const Text(
          'Battery Saver',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: const Text(
          'Allows Android to sleep the CPU, so ping timing may be less precise.',
          style: TextStyle(color: AppColors.textColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSpeedToggleCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: SwitchListTile(
        value: _showNetworkSpeed,
        onChanged: _onShowNetworkSpeedChanged,
        secondary: const Icon(Icons.speed, color: AppColors.primaryColor),
        title: const Text(
          'Display Network Speed',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _showNetworkSpeed
              ? 'Showing live download / upload speed'
              : 'Speed measurement is paused',
          style: const TextStyle(color: AppColors.textColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardAltColor,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _speedColumn(
              icon: Icons.arrow_downward,
              label: 'Download',
              bps: _downloadBps,
              formatter: NetworkSpeedMonitor.formatDownload,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _speedColumn(
              icon: Icons.arrow_upward,
              label: 'Upload',
              bps: _uploadBps,
              formatter: NetworkSpeedMonitor.formatUpload,
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedColumn({
    required IconData icon,
    required String label,
    required int? bps,
    required String Function(int) formatter,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textColor, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          bps == null ? '--' : formatter(bps),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
