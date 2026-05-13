import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Smart AI Fitness Coach – Design System
/// Palette from design brief:
///   FIT GREEN  : #F1DFCF  (lime accent – primary CTA)
///   FIT GREEN 40%: #7B7457 (muted green)
///   BLACK 88%  : #1E1E1E  (card surface)
///   BLACK      : #121212  (page background)
///   WHITE      : #FEF9F5  (text primary)
class AppTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color fitGreen = Color(0xFFC8F135);      // Lime / primary CTA
  static const Color fitGreenMuted = Color(0xFF7B9E3A);  // 40 % muted
  static const Color fitGreenDim = Color(0xFF2A3A10);    // background tint

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgPage = Color(0xFF0F0F0F);
  static const Color bgCard = Color(0xFF1A1A1A);
  static const Color bgCardAlt = Color(0xFF222222);
  static const Color bgSecondary = Color(0xFF252525);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textHint = Color(0xFF666666);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color statusGreen = Color(0xFFC8F135);
  static const Color statusRed = Color(0xFFFF4D4D);
  static const Color statusOrange = Color(0xFFFF9500);
  static const Color statusBlue = Color(0xFF4DA6FF);

  // ── Border ─────────────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFF2E2E2E);
  static const Color borderGreen = Color(0xFF3A5010);

  // ── Legacy aliases (backward compat with existing screens) ─────────────────
  static const Color primaryBlue = fitGreen;
  static const Color primaryBlueDark = fitGreenMuted;
  static const Color accentBlue = statusBlue;
  static const Color accentNeon = fitGreen;
  static const Color primaryDark = bgPage;

  // ── Shared decorations ─────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderLight, width: 1),
      );

  static BoxDecoration get cardDecorationGreen => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGreen, width: 1),
      );

  // ── Light theme (same dark palette – app is always dark-first) ─────────────
  static ThemeData get lightTheme => _buildTheme(isDark: false);
  static ThemeData get darkTheme => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final bg = isDark ? bgPage : const Color(0xFFF0F0F0);
    final surface = isDark ? bgCard : Colors.white;
    final onSurface = isDark ? textPrimary : const Color(0xFF111111);
    final secondary = isDark ? textSecondary : const Color(0xFF555555);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: fitGreen,
        onPrimary: Colors.black,
        secondary: fitGreenMuted,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: statusRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: onSurface),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: onSurface),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
          bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: onSurface),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? borderLight : const Color(0xFFE0E0E0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? bgCardAlt : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? borderLight : const Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? borderLight : const Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: fitGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusRed),
        ),
        labelStyle: TextStyle(fontSize: 14, color: isDark ? textSecondary : const Color(0xFF666666)),
        hintStyle: TextStyle(fontSize: 14, color: isDark ? textHint : const Color(0xFF999999)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fitGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fitGreen,
          side: const BorderSide(color: fitGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? fitGreen : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? fitGreen.withAlpha(80)
              : Colors.grey.withAlpha(60),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? fitGreen : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: fitGreen, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? bgCard : Colors.white,
        selectedItemColor: fitGreen,
        unselectedItemColor: isDark ? textHint : const Color(0xFF999999),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? borderLight : const Color(0xFFE8E8E8),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? bgCardAlt : Colors.white,
        contentTextStyle: TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
