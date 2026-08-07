import 'package:flutter/material.dart';
import 'package:netkeep/presentation/home/home.screen.dart';
import 'package:netkeep/presentation/profile/profile.screen.dart';
import 'package:netkeep/presentation/network/network.screen.dart';
import 'package:netkeep/presentation/settings/settings.screen.dart';
import 'package:netkeep/utils/theme.dart';
 

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  List screens = [
    HomeScreen(),
    ProfileScreen(),
    NetworkScreen(),
    SettingsScreen(),
  ];

  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       
      body: screens[activeIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.cardBgColor,
        currentIndex: activeIndex,
        onTap: (index) {
          setState(() {
            activeIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_backup_restore_outlined),
            label: "Profile",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: "Network"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
