import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color primaryColor = Color(0xFFF5A623);
  static const Color secondaryColor = Color(0xFF22C55E);
  static const Color tertiaryColor = Color(0xFFEF4444);
  static const Color white = Color(0xFFffffff);
  static const Color textColor = Color(0xFFADABAA);
  static const Color iconColor = Color(0xFFfdca7e);

  static const Color cardBgColor = Color(0xFF201f1f);
  // static const Color cardBgColor = Color(0xFF1a1a1a);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
     cardTheme: CardThemeData(
       color: AppColors.cardBgColor,
     ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    iconTheme: const IconThemeData(color: AppColors.iconColor,size: 25),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedIconTheme: IconThemeData(size: 20),
      unselectedIconTheme: IconThemeData(size: 20),
      backgroundColor: AppColors.cardBgColor,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.textColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: AppColors.iconColor),
      backgroundColor: AppColors.cardBgColor,
      elevation:  0,
      toolbarHeight: 60,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: AppColors.textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textColor,
      ),
    ),
  );
}
