import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/services/keep_alive_service.dart';
import 'package:netkeep/services/ping.services.dart';
import 'package:netkeep/services/vpn_service.dart';
import 'package:netkeep/services/wireguard_config.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  int _activeProfileIndex = 0;
  int _customIntervalSeconds = 5;
  bool isServiceRunning = false;
  late String _selectedIspUrl;
  late IspConfig _selectedIsp;
  final List<(String, String)> _logs = [];
  final PingService _pingService = PingService();

  // WireGuard relay state surfaced in the Live Console.
  String _vpnStage = 'disconnected';
  int? _vpnLatencyMs;
  StreamSubscription<Map<String, dynamic>>? _vpnEventSub;
  Timer? _vpnLatencyTimer;

  @override
  void initState() {
    super.initState();
    _selectedIspUrl = AppPreferences.selectedIspUrl;
    _selectedIsp = supportedIsps.firstWhere(
      (isp) => isp.url == _selectedIspUrl,
      orElse: () => supportedIsps.first,
    );
    _pingService.setTargetUrl(_selectedIspUrl);
    _vpnEventSub = VpnService.eventStream.listen(_onVpnEvent);
    _checkServiceStatus();
  }

  @override
  void dispose() {
    _vpnEventSub?.cancel();
    _vpnLatencyTimer?.cancel();
    _pingService.stopPing();
    super.dispose();
  }

  Future<void> _checkServiceStatus() async {
    final running = await KeepAliveManager.isServiceRunning();
    if (!mounted) return;
    setState(() {
      isServiceRunning = running;
    });
    await _refreshVpn();
  }

  Future<void> _refreshVpn() async {
    final snapshot = await VpnService.status();
    if (!mounted) return;
    final stage = snapshot['stage']?.toString() ?? 'disconnected';
    setState(() => _vpnStage = stage);
    if (stage == 'connected') {
      _startVpnLatencyProbe();
    }
  }

  void _onVpnEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    if (event['type'] != 'stage') return;
    final stage = event['stage']?.toString() ?? 'disconnected';
    setState(() => _vpnStage = stage);
    switch (stage) {
      case 'connected':
        _addHomeLog('WireGuard tunnel CONNECTED');
        _startVpnLatencyProbe();
      case 'connecting':
        _addHomeLog('WireGuard tunnel connecting...');
        _stopVpnLatencyProbe();
      case 'error':
        _addHomeLog('WireGuard tunnel error');
        _stopVpnLatencyProbe();
      default:
        _stopVpnLatencyProbe();
    }
  }

  void _onIspChanged(IspConfig isp) {
    setState(() {
      _selectedIsp = isp;
      _selectedIspUrl = isp.url;
    });
    AppPreferences.setSelectedIspUrl(isp.url);
    _pingService.setTargetUrl(isp.url);
    KeepAliveManager.updateTargetUrl(
      ispName: isp.name,
      targetUrl: isp.url,
    );
  }

  // Toggle the keep-alive state and start/stop the ping service
  Future<void> _toggleKeepAlive() async {
    if (isServiceRunning) {
      await KeepAliveManager.stopService();
      _pingService.stopPing();
      if (AppPreferences.vpnTunnelMode) {
        await VpnService.stop();
        _addHomeLog('WireGuard relay stopped');
      }
      if (!mounted) return;
      if (AppPreferences.autoClearConsole) {
        _logs.clear();
      }
    } else {
      // VPN Tunnel Mode: bring the WireGuard (WARP) relay up first so every
      // keep-alive ping egresses through the tunnel.
      if (AppPreferences.vpnTunnelMode) {
        _addHomeLog('Starting WireGuard tunnel (WARP)...');
        final config = await WireGuardConfigStore.load();
        final result = await VpnService.start(config);
        if (result['error'] != null) {
          _addHomeLog('Tunnel error: ${result['error']}');
        } else if (result['consentRequired'] == true) {
          _addHomeLog('Approve the VPN permission dialog');
        } else {
          _addHomeLog('Tunnel connecting...');
        }
        await VpnService.refreshStatus();
      }

      final started = await KeepAliveManager.startService(
        ispName: _selectedIsp.name,
        targetUrl: _selectedIsp.url,
      );
      if (!started || !mounted) return;
      _logs.clear();
      runProfile();
    }
    await _checkServiceStatus();
  }

  void _addHomeLog(String message) {
    final String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    _handleLog(("[$currentTime]", " $message"));
  }

  void _startVpnLatencyProbe() {
    _vpnLatencyTimer?.cancel();
    _vpnLatencyTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!isServiceRunning || _vpnStage != 'connected') return;
      final latency = await measureTunnelLatency();
      if (mounted && _vpnStage == 'connected') {
        setState(() => _vpnLatencyMs = latency);
      }
    });
  }

  void _stopVpnLatencyProbe() {
    _vpnLatencyTimer?.cancel();
    _vpnLatencyTimer = null;
    _vpnLatencyMs = null;
  }

  void _handleLog((String, String) log) {
    if (!mounted) return;
    setState(() {
      _logs.add(log);
    });
  }

  void runProfile() {
    switch (_activeProfileIndex) {
      case 0:
        _pingService.startNormalMode(_handleLog);
        break;
      case 2:
        _pingService.startCustomMode(_customIntervalSeconds, _handleLog);
        break;
      case 1:
        _pingService.startSaverMode(_handleLog);
        break;
      default:
        break;
    }
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
            onChanged: (index) => setState(() => _activeProfileIndex = index),
            customIntervalSeconds: _customIntervalSeconds,
            onCustomIntervalChanged: (value) =>
                setState(() => _customIntervalSeconds = value),
          ),
          const SizedBox(height: 28),
          LiveConsoleWidget(
            logs: _logs,
            vpnStage: _vpnStage,
            vpnLatencyMs: _vpnLatencyMs,
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
