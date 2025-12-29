import 'package:flutter/material.dart';

// Definición de la paleta de colores futurista
class AppColors {
  // Tema Oscuro
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFFFD700); // Amarillo Neón
  static const Color accentGreen = Color(0xFF00FF00); // Verde Neón
  static const Color accentBlue = Color(0xFF00FFFF); // Azul Neón

  // Tema Claro
  static const Color lightPrimaryText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF555555);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFF0052D4);
}

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'sans-serif', 
      bodyColor: AppColors.primaryText,
      displayColor: AppColors.primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentGreen,
        surface: AppColors.surface,
        error: Colors.redAccent,
        onPrimary: AppColors.background,
        onSecondary: AppColors.background,
        onSurface: AppColors.primaryText,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withAlpha(204)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.secondaryText,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = ThemeData.light().textTheme.apply(
      fontFamily: 'sans-serif', 
      bodyColor: AppColors.lightPrimaryText,
      displayColor: AppColors.lightPrimaryText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightAccent,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightAccent),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightSurface),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightAccent,
        secondary: AppColors.lightAccent,
        surface: AppColors.lightSurface,
        error: Colors.red,
        onPrimary: AppColors.lightSurface,
        onSecondary: AppColors.lightSurface,
        onSurface: AppColors.lightPrimaryText,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.lightPrimaryText),
        iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: AppColors.lightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightAccent,
        unselectedItemColor: AppColors.lightSecondaryText,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
