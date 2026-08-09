import 'package:flutter/material.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/isp.config.dart';
import 'package:netkeep/services/keep_alive_service.dart';
import 'package:netkeep/services/ping.services.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedIspUrl = AppPreferences.selectedIspUrl;
    _selectedIsp = supportedIsps.firstWhere(
      (isp) => isp.url == _selectedIspUrl,
      orElse: () => supportedIsps.first,
    );
    _pingService.setTargetUrl(_selectedIspUrl);
    _checkServiceStatus();
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
      if (!mounted) return;
      if (AppPreferences.autoClearConsole) {
        _logs.clear();
      }
    } else {
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

  void _handleLog((String, String) log) {
    if (!mounted) return;
    setState(() {
      _logs.add(log);
    });
    print(log);
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
  void dispose() {
    _pingService.stopPing();
    super.dispose();
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
          LiveConsoleWidget(logs: _logs),
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
