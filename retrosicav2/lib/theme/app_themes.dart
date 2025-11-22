import 'package:flutter/material.dart';

class AppThemes {
  // Purple color palette for dark theme
  static const purplePrimary = Color(0xFF8B5CF6);
  static const purpleSecondary = Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF6D28D9);
  static const purpleLight = Color(0xFFDDD6FE);
  static const purpleBackground = Color(0xFF1E1B4B);
  static const purpleSurface = Color(0xFF312E81);

  // Light theme colors
  static const lightPrimary = Color(0xFF6366F1);
  static const lightSecondary = Color(0xFF8B5CF6);
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: purplePrimary,
        secondary: purpleSecondary,
        surface: purpleSurface,
        background: purpleBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        primaryContainer: purpleDark,
        secondaryContainer: purpleDark,
      ),
      scaffoldBackgroundColor: purpleBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: purpleSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: purpleSurface,
        selectedItemColor: purpleSecondary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: purpleSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purplePrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.white),
      listTileTheme: ListTileThemeData(
        iconColor: purpleSecondary,
        textColor: Colors.white,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: purplePrimary,
        inactiveTrackColor: Colors.white24,
        thumbColor: purpleSecondary,
        overlayColor: purplePrimary.withOpacity(0.2),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        background: lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        primaryContainer: lightPrimary.withOpacity(0.1),
        secondaryContainer: lightSecondary.withOpacity(0.1),
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.black87),
      listTileTheme: ListTileThemeData(
        iconColor: lightSecondary,
        textColor: Colors.black87,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: lightPrimary,
        inactiveTrackColor: Colors.grey[300],
        thumbColor: lightSecondary,
        overlayColor: lightPrimary.withOpacity(0.2),
      ),
    );
  }
}