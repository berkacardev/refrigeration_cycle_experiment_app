// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand Colors ──────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const bg        = Color(0xFFF2F5F9);
  static const surface   = Color(0xFFFFFFFF);
  static const surface2  = Color(0xFFF7F9FC);
  static const divider   = Color(0xFFE4EAF2);

  // Hot / Kondenser
  static const hot       = Color(0xFFE53935);
  static const hotSoft   = Color(0xFFFFEBEE);
  static const hotMid    = Color(0xFFEF9A9A);
  static const water     = Color(0xFFFB8C00);
  static const waterSoft = Color(0xFFFFF3E0);

  // Cold / Evaporatör
  static const cold      = Color(0xFF1E88E5);
  static const coldSoft  = Color(0xFFE3F2FD);
  static const coldMid   = Color(0xFF90CAF9);

  // Evap chart purple
  static const evap      = Color(0xFF8E24AA);
  static const evapSoft  = Color(0xFFF3E5F5);

  // Saturation dashed
  static const saturation = Color(0xFFFFA000);

  // Status / Misc
  static const success   = Color(0xFF43A047);
  static const amber     = Color(0xFFF57C00);
  static const purple    = Color(0xFF7B1FA2);

  static const text1     = Color(0xFF1A2333);
  static const text2     = Color(0xFF4B5A6E);
  static const text3     = Color(0xFF8FA0B4);
}

// ── Typography ────────────────────────────────────────────────
class AppTextStyles {
  static TextStyle get mono => GoogleFonts.jetBrainsMono();
  static TextStyle get sans => GoogleFonts.inter();

  static TextStyle monoSm  ({Color? color, FontWeight? weight}) =>
      GoogleFonts.jetBrainsMono(fontSize: 10, color: color ?? AppColors.text3, fontWeight: weight ?? FontWeight.w400);

  static TextStyle monoBig ({Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: 28, fontWeight: FontWeight.w700, color: color ?? AppColors.text1, height: 1.0);

  static TextStyle label   ({Color? color}) =>
      GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color ?? AppColors.text3, letterSpacing: 1.2);

  static TextStyle unit    () =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text3);
}

// ── Theme ─────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.cold,
      brightness: Brightness.light,
      background: AppColors.bg,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.interTextTheme(),
    useMaterial3: true,
    dividerTheme: const DividerThemeData(color: AppColors.divider, space: 0),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      margin: EdgeInsets.zero,
    ),
  );
}

// ── Reusable decoration helpers ───────────────────────────────
BoxDecoration cardDecoration({required Color topBorder}) => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border(
    top:    BorderSide(color: topBorder, width: 3),
    left:   const BorderSide(color: AppColors.divider, width: 1.5),
    right:  const BorderSide(color: AppColors.divider, width: 1.5),
    bottom: const BorderSide(color: AppColors.divider, width: 1.5),
  ),
  boxShadow: const [
    BoxShadow(color: Color(0x0F1E3250), blurRadius: 8, offset: Offset(0,2)),
  ],
);
