import 'package:flutter/material.dart';

/// App-wide color system following the HomePage styling.
abstract class AppColors {
  // Brand
  static const primary = Color(0xFF111827); // Cool Gray 900
  static const accent = Color(0xFF6366F1); // Indigo 500

  // Backgrounds
  static const background = Color(0xFFF3F4F6); // Cool Gray 100
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF9FAFB); // Cool Gray 50

  // Text
  static const textPrimary = Color(0xFF111827); // Cool Gray 900
  static const textSecondary = Color(0xFF6B7280); // Cool Gray 500
  static const textTertiary = Color(0xFF9CA3AF); // Cool Gray 400

  // Status
  static const success = Color(0xFF10B981); // Emerald 500
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const error = Color(0xFFEF4444); // Red 500
  static const info = Color(0xFF3B82F6); // Blue 500

  // Status Backgrounds (Light)
  static final successLight = success.withValues(alpha: 0.1);
  static final warningLight = warning.withValues(alpha: 0.1);
  static final errorLight = error.withValues(alpha: 0.1);
  static final infoLight = info.withValues(alpha: 0.1);
}
