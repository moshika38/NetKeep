import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/home_widgets/app.header.dart';
import 'package:netkeep/widgets/home_widgets/home.app.bar.dart';
import 'package:netkeep/widgets/settings_widgets/settings.tile.dart';
import 'package:netkeep/widgets/settings_widgets/toggle.tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool speedNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar.homeAppBar(context, "Settings"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(
              title: "Notifications",
              subtitle: "Manage app alerts",
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              child: ToggleTile(
                icon: Icons.speed,
                color: AppColors.primaryColor,
                title: "Notification",
                subtitle: speedNotificationEnabled
                    ? "Shows current network speed in the status bar"
                    : "Network speed alerts are muted",
                value: speedNotificationEnabled,
                onChanged: (value) =>
                    setState(() => speedNotificationEnabled = value),
              ),
            ),
            const SizedBox(height: 24),
            const AppHeader(
              title: "About",
              subtitle: "App information & policies",
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              child: Column(
                children: [
                  const SettingsTile(
                    icon: Icons.info_outline,
                    color: AppColors.primaryColor,
                    title: "App Version",
                    subtitle: "1.0.0 (build 1)",
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: AppColors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    color: AppColors.secondaryColor,
                    title: "Privacy Policy",
                    subtitle: "How we handle your data",
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: AppColors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.policy_outlined,
                    color: AppColors.tertiaryColor,
                    title: "Terms of Service",
                    subtitle: "App usage terms",
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
