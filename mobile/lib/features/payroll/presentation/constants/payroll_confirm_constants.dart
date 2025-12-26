import 'package:flutter/material.dart';

/// Payroll confirmation constants
class PayrollConfirmConstants {
  PayrollConfirmConstants._();

  /// Currency code
  static const String currencyCode = 'KES';

  /// Default phone prefix
  static const String defaultPhonePrefix = '07';

  /// Default topup amount when no shortfall
  static const double defaultTopupAmount = 1000.0;

  /// Simulated STK push delay
  static const Duration stkPushDelay = Duration(seconds: 1);

  /// Routes
  static const String homeRoute = '/home';
}

/// Payroll confirmation theme
class PayrollConfirmTheme {
  PayrollConfirmTheme._();

  // M-Pesa green
  static const Color mpesaGreen = Color(0xFF00D632);

  // Status colors
  static const Color successGreen = Colors.green;
  static const Color errorRed = Colors.red;
  static const Color warningOrange = Colors.orange;

  // Background colors
  static const Color successBgLight = Color(0xFFF0FDF4); // Green-50
  static const Color errorBgLight = Color(0xFFFEF2F2);   // Red-50

  // Card styling
  static const double cardBorderRadius = 16.0;
  static const double bottomSheetRadius = 24.0;
  static const double buttonRadius = 16.0;

  // Wallet card decoration
  static BoxDecoration walletCardDecoration({required bool isSufficient}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      border: Border.all(
        color: isSufficient ? Colors.grey.shade200 : Colors.red.shade200,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Bottom sheet decoration
  static const BoxDecoration bottomSheetDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(bottomSheetRadius)),
  );

  // M-Pesa button style
  static ButtonStyle get mpesaButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: mpesaGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        elevation: 0,
      );

  // Primary action button style
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: Colors.grey.shade300,
      );

  // Dark button style (for results page)
  static ButtonStyle get darkButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      );
}

/// Snackbar helpers
class PayrollConfirmSnackbars {
  PayrollConfirmSnackbars._();

  static SnackBar loading(String message) {
    return SnackBar(content: Text(message));
  }

  static SnackBar success(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: PayrollConfirmTheme.successGreen,
    );
  }

  static SnackBar error(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: PayrollConfirmTheme.errorRed,
    );
  }
}
