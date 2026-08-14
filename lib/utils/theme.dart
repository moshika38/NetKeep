import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm dark + orange/amber palette.
///
/// The app's identity stays terminal-ish (monospace type, faint grid, corner
/// brackets) but the harsh all-square cyan scheme is replaced with layered
/// warm-black surfaces, a vivid orange primary and rounded geometry so it
/// reads as a polished tool instead of a debug console.
/// Cyberpunk / High-Tech Cyber dark palette with HUD styling.
class AppColors {
  // Surfaces - deep cyber obsidian & matrix dark navy.
  static const Color backgroundColor = Color(0xFF080B11);
  static const Color cardBgColor = Color(0xFF0F1420);
  static const Color cardAltColor = Color(0xFF141B2D);

  // Brand - Cyber Electric Cyan & Laser Violet.
  static const Color primaryColor = Color(0xFF00F0FF);
  static const Color accentColor = Color(0xFF7000FF);
  static const Color glowColor = Color(0xFF00D2FF);

  // Semantic states - Neon Emerald Green & Crimson Red.
  static const Color secondaryColor = Color(0xFF00FFA3);
  static const Color tertiaryColor = Color(0xFFFF2A6D);
  static const Color warningColor = Color(0xFFFFB800);

  // Text & chrome.
  static const Color white = Color(0xFFF0F6FC);
  static const Color textColor = Color(0xFF8B949E);
  static const Color iconColor = Color(0xFF00F0FF);
  static const Color borderColor = Color(0x3300F0FF);
}

/// Shared corner radii so every screen is consistent.
class AppRadii {
  static const double card = 16;
  static const double control = 12;
  static const double tile = 10;
  static const double chip = 8;
  static const double button = 12;
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
        side: const BorderSide(color: AppColors.borderColor),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundColor.withValues(alpha: 0.92),
      elevation: 0,
      centerTitle: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.primaryColor),
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
        backgroundColor: AppColors.primaryColor,
        foregroundColor: const Color(0xFF080B11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        textStyle: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
            ? AppColors.primaryColor.withValues(alpha: 0.3)
            : Colors.white12,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) => null),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cardBgColor,
      selectedColor: AppColors.primaryColor.withValues(alpha: 0.16),
      side: const BorderSide(color: AppColors.borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textColor,
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
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
        side: const BorderSide(color: AppColors.borderColor),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardBgColor,
      indicatorColor: AppColors.primaryColor.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
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
          letterSpacing: 1.6,
          fontFamily: GoogleFonts.orbitron().fontFamily,
          color: selected ? AppColors.primaryColor : AppColors.textColor,
        );
      }),
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.white,
      ),
      titleMedium: GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        color: AppColors.textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        color: AppColors.textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
        color: AppColors.textColor,
      ),
    ),
  );
}
