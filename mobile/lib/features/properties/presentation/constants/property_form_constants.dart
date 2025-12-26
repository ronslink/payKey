import 'package:flutter/material.dart';

class PropertyFormTheme {
  // Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  
  static Color get glassBackground => Colors.white.withValues(alpha: 0.05);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.1);
  
  static const List<Color> backgroundGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];
  
  static List<Color> get iconGradient => [
    Colors.white.withValues(alpha: 0.15),
    Colors.white.withValues(alpha: 0.05),
  ];


  static const Color blueOrbColor = Color(0x333B82F6); // 0.2 opacity
  static const Color greenOrbColor = Color(0x2610B981); // 0.15 opacity

  // Dimensions
  static const double cardBorderRadius = 24.0;
  static const double cardPadding = 24.0;
  static const double fieldSpacing = 20.0;
  static const double headerIconRadius = 12.0;
  static const double sectionIconRadius = 14.0;
  static const double chipBorderRadius = 8.0;

  static const double topOrbSize = 400.0;
  static const double bottomOrbSize = 300.0;

  // Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    disabledBackgroundColor: primaryBlue.withValues(alpha: 0.5),
    padding: const EdgeInsets.symmetric(vertical: 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    shadowColor: primaryBlue.withValues(alpha: 0.5),
  );

  static InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      prefixIcon: Icon(icon, color: lightBlue),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      helperText: helperText,
      helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
    );
  }
}

class PropertyFormConstants {
  static const Duration animationDuration = Duration(milliseconds: 500);
  
  static const double glassBlurSigma = 20.0;
  static const double decorativeBlurSigma = 80.0;

  static const int minGeofenceRadius = 10;
  static const int maxGeofenceRadius = 5000;
  static const int defaultGeofenceRadius = 100;

  // Regex for coordinate detection: e.g. "-1.223, 36.87"
  static final RegExp coordinatesRegex = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
}

class PropertyFormSnackbars {
  static SnackBar success(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
      backgroundColor: PropertyFormTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    );
  }

  static SnackBar error(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: PropertyFormTheme.errorRed,
      behavior: SnackBarBehavior.floating,
    );
  }
}
