import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryOrange = Color(0xFFFF8C42);
  static const Color lightOrange = Color(0xFFFFF0E6);
  static const Color accentBlue = Color(0xFF4FA8D5);
  static const Color lightBlue = Color(0xFFE8F4FD);
  static const Color bgWhite = Color(0xFFFDFDFD);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3142);
  static const Color textMedium = Color(0xFF5A6070);
  static const Color textLight = Color(0xFF9BA3B4);
  static const Color divider = Color(0xFFEEF0F5);
  static const Color heartRed = Color(0xFFE94F6A);
  static const Color successGreen = Color(0xFF4CAF7D);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.nunitoTextTheme(),
    colorScheme: const ColorScheme.light(
      primary: primaryOrange,
      secondary: accentBlue,
      surface: bgWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: bgWhite,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: cardWhite,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textMedium, fontSize: 14),
      hintStyle: const TextStyle(color: textLight, fontSize: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryOrange,
      unselectedItemColor: textLight,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
  );
}
