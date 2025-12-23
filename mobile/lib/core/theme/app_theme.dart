import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // Brand Colors
  static const _seedColor = Color(0xFF3B82F6); // Professional Blue
  static const _secondaryColor = Color(0xFF6366F1); // Indigo
  static const _backgroundColor = Color(0xFFF3F4F6); // Soft Grey Background
  
  // Text Colors
  static const _textPrimary = Color(0xFF111827); // Cool Gray 900
  static const _textSecondary = Color(0xFF4B5563); // Cool Gray 600

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      primary: _seedColor,
      secondary: _secondaryColor,
      surface: Colors.white,
      surfaceContainerHighest: _backgroundColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: _backgroundColor,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: _textPrimary,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    ),
    
    // Text Theme (Inter)
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: _textPrimary,
      displayColor: _textPrimary,
    ),
    
    // Card Theme - Clean & Modern
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _seedColor,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        foregroundColor: _textPrimary,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _seedColor, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: _textSecondary),
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
}
