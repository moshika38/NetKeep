import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color backgroundColor = Color(0xFF050A0B);
  static const Color cardBgColor = Color(0xFF0B1113);
  static const Color cardAltColor = Color(0xFF0F171A);
  static const Color primaryColor = Color(0xFF00E5FF);
  static const Color accentColor = Color(0xFF7C4DFF);
  static const Color secondaryColor = Color(0xFF00E876);
  static const Color tertiaryColor = Color(0xFFFF4D5E);
  static const Color white = Color(0xFFF2FAFC);
  static const Color textColor = Color(0xFF87A0A8);
  static const Color iconColor = Color(0xFF00E5FF);
  static const Color borderColor = Color(0x14FFFFFF);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: AppColors.cardBgColor,
      outline: AppColors.borderColor,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
    cardTheme: const CardThemeData(
      color: AppColors.cardBgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.borderColor),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundColor.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textColor),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderColor, thickness: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.iconColor,
      textColor: AppColors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderColor),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
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
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardBgColor,
      indicatorColor: AppColors.primaryColor.withValues(alpha: 0.14),
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.primaryColor),
      ),
      height: 64,
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
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.8,
          color: selected ? AppColors.primaryColor : AppColors.textColor,
        );
      }),
    ),
    textTheme: TextTheme(
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.white,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
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
        letterSpacing: 0.4,
        color: AppColors.textColor,
      ),
    ),
  );
}
