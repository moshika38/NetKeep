import 'package:flutter/material.dart';
import 'package:netkeep/presentation/home/home.screen.dart';
import 'package:netkeep/presentation/network/network.screen.dart';
import 'package:netkeep/presentation/settings/settings.screen.dart';
import 'package:netkeep/services/ad_manager.dart';
import 'package:netkeep/services/permission_service.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/banner_ad_widget.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  static const _screens = [
    HomeScreen(),
    NetworkScreen(),
    SettingsScreen(),
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
      AdManager.instance.loadInterstitialAd();
    });
  }

  Future<void> _checkNotificationPermission() async {
    await PermissionService.checkAndRequestNotificationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BannerAdWidget(),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (index) => setState(() => _index = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'HOME',
                  ),
                  NavigationDestination(icon: Icon(Icons.speed), label: 'NETWORK'),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'SETTINGS',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
