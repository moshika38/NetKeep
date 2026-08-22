import 'package:flutter/material.dart';
import 'package:netkeep/presentation/shell/shell.screen.dart';
import 'package:netkeep/presentation/update/update_lock_screen.dart';
import 'package:netkeep/services/app_update_service.dart';
import 'package:netkeep/widgets/app.background.dart';
import 'package:netkeep/widgets/app.loading.indicator.dart';

/// Guard widget checking Google Play Store for mandatory app updates before allowing
/// access to the main NetKeep application UI.
class AppUpdateGuard extends StatefulWidget {
  const AppUpdateGuard({super.key});

  @override
  State<AppUpdateGuard> createState() => _AppUpdateGuardState();
}

class _AppUpdateGuardState extends State<AppUpdateGuard>
    with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppUpdateStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppUpdateStatus();
    }
  }

  Future<void> _checkAppUpdateStatus() async {
    final info = await AppUpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _updateRequired = info.updateAvailable;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: AppLoadingIndicator(size: 120.0),
          ),
        ),
      );
    }

    if (_updateRequired) {
      return const UpdateLockScreen();
    }

    return const AppBackground(child: ShellScreen());
  }
}
