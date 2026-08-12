import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm dark + orange/amber palette.
///
/// The app's identity stays terminal-ish (monospace type, faint grid, corner
/// brackets) but the harsh all-square cyan scheme is replaced with layered
/// warm-black surfaces, a vivid orange primary and rounded geometry so it
/// reads as a polished tool instead of a debug console.
class AppColors {
  // Surfaces - deep, slightly warm near-black.
  static const Color backgroundColor = Color(0xFF0D0B09);
  static const Color cardBgColor = Color(0xFF151210);
  static const Color cardAltColor = Color(0xFF1C1815);

  // Brand - orange primary, amber accent.
  static const Color primaryColor = Color(0xFFFF7A1A);
  static const Color accentColor = Color(0xFFFFB84D);
  static const Color glowColor = Color(0xFFFF8A2E);

  // Semantic states.
  static const Color secondaryColor = Color(0xFF4ADE80);
  static const Color tertiaryColor = Color(0xFFFF5A5F);

  // Text & chrome.
  static const Color white = Color(0xFFFBF5EE);
  static const Color textColor = Color(0xFFA9A09A);
  static const Color iconColor = Color(0xFFFF8C38);
  static const Color borderColor = Color(0x1FFFFFFF);
}

/// Shared corner radii so every screen is consistent.
class AppRadii {
  static const double card = 18;
  static const double control = 14;
  static const double tile = 12;
  static const double chip = 10;
  static const double button = 14;
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.accentColor,
      surface: AppColors.cardBgColor,
      error: AppColors.tertiaryColor,
      outline: AppColors.borderColor,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
    cardTheme: CardThemeData(
      color: AppColors.cardBgColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: AppColors.borderColor),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundColor.withValues(alpha: 0.88),
      elevation: 0,
      centerTitle: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textColor),
    ),
    dividerTheme:
        const DividerThemeData(color: AppColors.borderColor, thickness: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.iconColor,
      textColor: AppColors.white,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryColor,
      linearTrackColor: Colors.white10,
      linearMinHeight: 8,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor
            : Colors.white38,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor.withValues(alpha: 0.35)
            : Colors.white12,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) => null),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cardBgColor,
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.16),
      side: BorderSide(color: AppColors.borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textColor,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: AppColors.borderColor),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardBgColor,
      indicatorColor: AppColors.primaryColor.withValues(alpha: 0.16),
      indicatorShape: const StadiumBorder(),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primaryColor : AppColors.textColor,
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 10,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: 1.4,
          color: selected ? AppColors.primaryColor : AppColors.textColor,
        );
      }),
    ),
    textTheme: TextTheme(
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: AppColors.white,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.white,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textColor,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textColor,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textColor,
      ),
    ),
  );
}
