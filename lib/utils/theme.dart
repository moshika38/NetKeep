import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color cardBgColor = Color(0xFF1A1A1A);
  static const Color primaryColor = Color(0xFFF5A623);
  static const Color secondaryColor = Color(0xFF22C55E);
  static const Color tertiaryColor = Color(0xFFEF4444);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFFADABAA);
  static const Color iconColor = Color(0xFFF5A623);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: AppColors.cardBgColor,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    cardTheme: const CardThemeData(
      color: AppColors.cardBgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardBgColor,
      elevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textColor),
    ),
    dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.iconColor,
      textColor: AppColors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor
            : Colors.white30,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryColor.withValues(alpha: 0.4)
            : Colors.white12,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardBgColor,
      indicatorColor: AppColors.primaryColor.withValues(alpha: 0.2),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primaryColor : AppColors.textColor,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primaryColor : AppColors.textColor,
        );
      }),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textColor,
      ),
    ),
  );
}
