import 'package:flutter/material.dart';
import 'package:netkeep/presentation/home/home.screen.dart';
import 'package:netkeep/presentation/profile/profile.screen.dart';
import 'package:netkeep/presentation/network/network.screen.dart';
import 'package:netkeep/presentation/settings/settings.screen.dart';
import 'package:netkeep/widgets/bottom.nav.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  List screens = [
    HomeScreen(),
    NetworkScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       
      body: screens[activeIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: activeIndex,
        onChanged: (index) {
          setState(() {
            activeIndex = index;
          });
        },
        icons: const [
          Icons.dashboard_customize_outlined,
          Icons.speed,
          Icons.settings_backup_restore_outlined,
          Icons.settings_outlined,
        ],
        labels: const ["Home", "Network","Profile", "Settings"],
      ),
    );
  }
}
