import 'package:flutter/material.dart';

/// Theme-aware color tokens accessed via BuildContext.
///
/// Replaces hardcoded `Colors.grey.shade*` usage throughout the app so
/// that text, icons, borders and surfaces automatically adapt to the
/// current brightness (light / dark).
///
/// Usage:
/// ```dart
/// Text('Hello', style: TextStyle(color: context.textSecondary));
/// Icon(Icons.info, color: context.iconMuted);
/// Container(decoration: BoxDecoration(border: Border.all(color: context.borderDefault)));
/// ```
extension PayColors on BuildContext {
  // ---------------------------------------------------------------------------
  // Convenience accessors
  // ---------------------------------------------------------------------------
  ColorScheme get _cs => Theme.of(this).colorScheme;
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // ---------------------------------------------------------------------------
  // TEXT COLORS
  // ---------------------------------------------------------------------------

  /// Primary content text — headings, body copy, important values.
  /// Light: Cool Gray 900  |  Dark: ~E0E0E0
  Color get textPrimary => _cs.onSurface;

  /// Secondary content text — subtitles, descriptions, metadata.
  /// Light: Cool Gray 600  |  Dark: theme onSurfaceVariant
  Color get textSecondary => _cs.onSurfaceVariant;

  /// Tertiary / muted text — captions, disabled labels, timestamps.
  /// Light: Cool Gray 400  |  Dark: outline
  Color get textTertiary => _cs.outline;

  // ---------------------------------------------------------------------------
  // ICON COLORS
  // ---------------------------------------------------------------------------

  /// Default icon color — action icons, navigation icons.
  Color get iconDefault => _cs.onSurfaceVariant;

  /// Muted icon color — decorative, empty-state, placeholder icons.
  Color get iconMuted => _cs.outline;

  // ---------------------------------------------------------------------------
  // SURFACE / BACKGROUND COLORS
  // ---------------------------------------------------------------------------

  /// Primary surface — cards, sheets, dialogs.
  Color get surfacePrimary => _cs.surface;

  /// Alternate / elevated surface — section backgrounds, list headers.
  Color get surfaceAlt => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6);

  /// Muted surface — input fills, tag backgrounds.
  Color get surfaceMuted => _isDark ? const Color(0xFF252525) : const Color(0xFFF9FAFB);

  // ---------------------------------------------------------------------------
  // BORDER / DIVIDER COLORS
  // ---------------------------------------------------------------------------

  /// Default border — cards, containers, outlines.
  Color get borderDefault => Theme.of(this).dividerColor;

  /// Muted / subtle border — inner dividers, progress bar tracks.
  Color get borderMuted => _isDark ? Colors.grey.shade800 : Colors.grey.shade200;

  /// Strong border — focused / highlighted containers.
  Color get borderStrong => _isDark ? Colors.grey.shade600 : Colors.grey.shade400;
}
