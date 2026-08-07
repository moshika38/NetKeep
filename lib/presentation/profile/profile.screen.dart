import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/home_widgets/app.header.dart';
import 'package:netkeep/widgets/home_widgets/home.app.bar.dart';
import 'package:netkeep/widgets/profile_widgets/profile.mode.card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar.homeAppBar(context, "Profiles"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(
              title: "Keep-Alive Profiles",
              subtitle: "How each mode works",
            ),
            const SizedBox(height: 14),
            const ProfileModeCard(
              icon: Icons.sync,
              title: "Normal Mode",
              subtitle: "Balanced Performance",
              badge: "Standard | 5s Interval",
              accent: AppColors.primaryColor,
              specs: [
                ProfileModeSpec("Interval", "Every 5 seconds"),
                ProfileModeSpec("CPU Wakelock", "Disabled"),
                ProfileModeSpec("Battery Impact", "Low"),
                ProfileModeSpec(
                  "Best For",
                  "Daily Browsing & Social Media",
                ),
              ],
              description:
                  "Maintains a steady connection with minimal battery impact. Prevents background connection drops during everyday app usage.",
            ),
            const SizedBox(height: 14),
            const ProfileModeCard(
              icon: Icons.battery_charging_full,
              title: "Saver Mode",
              subtitle: "Maximum Battery Saver",
              badge: "Eco | 20s Interval",
              accent: AppColors.secondaryColor,
              specs: [
                ProfileModeSpec("Interval", "Every 20 seconds"),
                ProfileModeSpec("CPU Wakelock", "Disabled"),
                ProfileModeSpec("Battery Impact", "Ultra Low"),
                ProfileModeSpec(
                  "Best For",
                  "Background Downloads & Long Idle",
                ),
              ],
              description:
                  "Pings naturally when your phone wakes up. Preserves maximum battery life while keeping long background downloads active.",
            ),
            const SizedBox(height: 14),
            const ProfileModeCard(
              icon: Icons.sports_esports,
              title: "Game Mode",
              subtitle: "Low Latency & Ultra Stability",
              badge: "High Performance | 2s Interval",
              accent: AppColors.tertiaryColor,
              specs: [
                ProfileModeSpec("Interval", "Every 2 seconds"),
                ProfileModeSpec("CPU Wakelock", "Enabled (Persistent)"),
                ProfileModeSpec("Battery Impact", "High"),
                ProfileModeSpec("Best For", "Online Multiplayer Gaming"),
              ],
              description:
                  "Forces the CPU to stay active to eliminate lag spikes, packet drops, and latency fluctuations during intense gaming sessions.",
            ),
          ],
        ),
      ),
    );
  }
}
