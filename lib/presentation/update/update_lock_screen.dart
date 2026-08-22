import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netkeep/services/app_update_service.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.background.dart';

/// Mandatory non-bypassable lock screen shown when a Google Play update is required.
class UpdateLockScreen extends StatefulWidget {
  const UpdateLockScreen({super.key});

  @override
  State<UpdateLockScreen> createState() => _UpdateLockScreenState();
}

class _UpdateLockScreenState extends State<UpdateLockScreen> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerUpdate();
    });
  }

  Future<void> _triggerUpdate() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await AppUpdateService.performImmediateUpdate();
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Intentionally block back button navigation during mandatory update.
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgColor,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warningColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'MANDATORY UPDATE REQUIRED',
                          style: TextStyle(
                            color: AppColors.warningColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Update NetKeep to Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: GoogleFonts.orbitron().fontFamily,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A critical app update is available on Google Play. '
                        'You must update NetKeep to the latest version to ensure '
                        'service reliability and security before using the application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _triggerUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: const Color(0xFF080B11),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.button),
                            ),
                          ),
                          icon: _isUpdating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF080B11),
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            _isUpdating ? 'INITIALIZING UPDATE...' : 'UPDATE NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.4,
                              fontFamily: GoogleFonts.orbitron().fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
