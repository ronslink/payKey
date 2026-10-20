import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

abstract class AppTheme {
  static const primaryColor = AppColors.primary;

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final background = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF3F4F6);
    final foreground = isDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF111827);
    final secondaryText = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF4B5563);
    final border = isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB);
    final inputBorder = isDark
        ? const Color(0xFF737373)
        : const Color(0xFF6B7280);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: brightness,
      primary: isDark ? AppColors.primaryDark : AppColors.primary,
      onPrimary: isDark ? AppColors.onPrimaryDark : AppColors.onPrimary,
      secondary: isDark ? const Color(0xFFA5B4FC) : AppColors.accent,
      surface: surface,
      onSurface: foreground,
      onSurfaceVariant: secondaryText,
      surfaceContainerHighest: background,
      outline: inputBorder,
      outlineVariant: border,
    );
    final text = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: foreground, displayColor: foreground);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final primaryButton = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      minimumSize: const Size(48, 48),
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: buttonShape,
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: buttonShape,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          foregroundColor: foreground,
          side: BorderSide(color: inputBorder),
          shape: buttonShape,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(16),
        border: outline(inputBorder),
        enabledBorder: outline(inputBorder),
        focusedBorder: outline(scheme.primary, 2),
        errorBorder: outline(scheme.error),
        focusedErrorBorder: outline(scheme.error, 2),
        labelStyle: GoogleFonts.inter(color: secondaryText),
        floatingLabelStyle: GoogleFonts.inter(color: scheme.primary),
        hintStyle: GoogleFonts.inter(color: secondaryText),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: text.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: secondaryText,
        textColor: foreground,
      ),
    );
  }
}
