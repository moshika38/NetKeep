import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/isp.config.dart';
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
  final int _intervalSeconds = AppPreferences.pingIntervalSeconds;
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 14),
                  _buildServiceButton(),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  _buildToggleCard(
                    icon: Icons.battery_saver_outlined,
                    iconColor: AppColors.secondaryColor,
                    title: 'Battery Saver',
                    subtitle:
                        'Allows Android to sleep the CPU, so ping timing may '
                        'be less precise.',
                    value: _batterySaver,
                    onChanged: _onBatterySaverChanged,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    icon: Icons.speed,
                    iconColor: AppColors.primaryColor,
                    title: 'Display Network Speed',
                    subtitle: _showNetworkSpeed
                        ? 'Showing live download / upload speed'
                        : 'Speed measurement is paused',
                    value: _showNetworkSpeed,
                    onChanged: _onShowNetworkSpeedChanged,
                  ),
                  if (_showNetworkSpeed && isServiceRunning) ...[
                    const SizedBox(height: 12),
                    _buildSpeedCard(),
                  ],
                  const SizedBox(height: 24),
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
    final running = isServiceRunning;
    final statusColor = running
        ? AppColors.secondaryColor
        : AppColors.tertiaryColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: statusColor.withValues(alpha: running ? 0.4 : 0.25),
        ),
        boxShadow: running
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.07),
                  blurRadius: 26,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _PulseDot(color: statusColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      running ? 'SERVICE ACTIVE' : 'SERVICE OFF',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (running) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.secondaryColor.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  running
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
          _buildIconTile(
            icon: running ? Icons.sync : Icons.power_settings_new,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton() {
    final running = isServiceRunning;
    final colors = running
        ? const [AppColors.tertiaryColor, Color(0xFF9E241C)]
        : const [AppColors.primaryColor, AppColors.accentColor];
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadii.button),
          boxShadow: running
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.button),
          onTap: _toggleService,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  running
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  running ? 'STOP SERVICE' : 'START SERVICE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: _buildIconTile(icon: icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardAltColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _speedColumn(
              icon: Icons.arrow_downward,
              iconColor: AppColors.primaryColor,
              label: 'Download',
              bps: _downloadBps,
              formatter: NetworkSpeedMonitor.formatDownload,
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.borderColor),
          Expanded(
            child: _speedColumn(
              icon: Icons.arrow_upward,
              iconColor: AppColors.accentColor,
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
    required Color iconColor,
    required String label,
    required int? bps,
    required String Function(int) formatter,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 8),
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
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildIconTile({required IconData icon, required Color color}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Pulsing status indicator: a soft halo that breathes around a solid dot.
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween(begin: 0.85, end: 1.6).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.16),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.7),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
