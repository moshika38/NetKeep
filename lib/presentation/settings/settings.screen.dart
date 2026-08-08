import 'package:flutter/material.dart';
import 'package:netkeep/services/app.info.service.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.bar.dart';
import 'package:netkeep/widgets/section.header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _speedNotifications = true;
  bool _autoClearConsole = AppPreferences.autoClearConsole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NetKeepAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Notifications',
            subtitle: 'Manage app alerts',
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              value: _speedNotifications,
              onChanged: (value) => setState(() => _speedNotifications = value),
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.speed,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              title: const Text(
                'Network Speed Alert',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _speedNotifications
                    ? 'Shows current speed in the status bar'
                    : 'Speed alerts are muted',
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Console',
            subtitle: 'Live console behavior',
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              value: _autoClearConsole,
              onChanged: (value) {
                setState(() => _autoClearConsole = value);
                AppPreferences.setAutoClearConsole(value);
              },
              secondary: const _TileIcon(
                icon: Icons.cleaning_services,
                color: AppColors.tertiaryColor,
              ),
              title: const Text(
                'Auto Clear Console',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _autoClearConsole
                    ? 'Clears logs when keep-alive stops'
                    : 'Keeps logs after keep-alive stops',
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'About',
            subtitle: 'App information & policies',
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const _TileIcon(
                    icon: Icons.info_outline,
                    color: AppColors.primaryColor,
                  ),
                  title: const _TileTitle('App Version'),
                  subtitle: FutureBuilder<String>(
                    future: AppInfoService.getAppVersion(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!);
                      }
                      return const Text('v1.0.0');
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const _TileIcon(
                    icon: Icons.privacy_tip_outlined,
                    color: AppColors.secondaryColor,
                  ),
                  title: const _TileTitle('Privacy Policy'),
                  subtitle: const Text('How we handle your data'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const _TileIcon(
                    icon: Icons.policy_outlined,
                    color: AppColors.tertiaryColor,
                  ),
                  title: const _TileTitle('Terms of Service'),
                  subtitle: const Text('App usage terms'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _TileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TileTitle extends StatelessWidget {
  final String text;
  const _TileTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    );
  }
}
