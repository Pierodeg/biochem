import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tema Material3 dell'applicazione Biochem
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryBright,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,

      // --- AppBar ---
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0x4D000000), // glassDarkest
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // --- Campi di testo ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00A843), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0x99FFFFFF)),
        hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
        prefixIconColor: const Color(0x99FFFFFF),
      ),

      // --- Pulsante elevato ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonPrimaryText,
          disabledBackgroundColor: AppColors.buttonDisabled,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // --- FAB ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.fabBackground,
        foregroundColor: AppColors.fabIcon,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // --- Card ---
      cardTheme: CardThemeData(
        color: const Color(0x12FFFFFF), // glassCard
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0x26FFFFFF), // glassBorder
            width: 0.5,
          ),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // --- BottomAppBar ---
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.navBackground,
        elevation: 8,
        shadowColor: Colors.black26,
      ),

      // --- Drawer ---
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        elevation: 16,
      ),
    );
  }
}
