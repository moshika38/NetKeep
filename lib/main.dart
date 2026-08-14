import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:netkeep/presentation/shell/shell.screen.dart';
import 'package:netkeep/services/app.preferences.dart';
import 'package:netkeep/services/keep_alive_service.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await MobileAds.instance.initialize();
  await AppPreferences.init();
  KeepAliveManager.initService();
  runApp(const NetKeep());
}

class NetKeep extends StatelessWidget {
  const NetKeep({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetKeep',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AppBackground(child: ShellScreen()),
    );
  }
}
