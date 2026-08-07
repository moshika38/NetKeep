import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
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
  bool _isRunning = false;

  void _toggleKeepAlive() {
    setState(() => _isRunning = !_isRunning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NetKeepAppBar(title: 'NetKeep'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'NetKeep Status',
            subtitle: 'Connection control center',
          ),
          const SizedBox(height: 12),
          _StatusCard(running: _isRunning),
          const SizedBox(height: 16),
          SizedBox(height: 55,
            child: FilledButton.icon(
               
              onPressed: _toggleKeepAlive,
              icon: Icon(_isRunning ? Icons.stop : Icons.power_settings_new),
              label: Text(_isRunning ? 'Stop Keep-Alive' : 'Start Keep-Alive'),
              style: FilledButton.styleFrom(
                backgroundColor: _isRunning
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
          ),
          const SizedBox(height: 28),
          const LiveConsoleWidget(),
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
        child: Center(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                running ? Icons.wifi : Icons.wifi_off,
                color: color,
                size: 22,
              ),
            ),
            title: Text(
              running ? 'Connected' : 'Disconnected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(running ? 'Keep-Alive is active' : 'Connection is idle'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    running ? 'Active' : 'Idle',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
