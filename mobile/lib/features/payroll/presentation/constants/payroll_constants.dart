/// Payroll feature constants
class PayrollConstants {
  PayrollConstants._();

  // Progress steps
  static const int employeeInputStep = 1;
  static const int reviewStep = 2;
  static const int confirmationStep = 3;
  static const int totalProgressSteps = 3;

  // Tax year
  static int get currentTaxYear => DateTime.now().year;

  // Hours
  static const double defaultMonthlyHours = 160.0;
  static const double defaultOvertimeHours = 0.0;
  static const double overtimeMultiplier = 1.5;

  // UI
  static const double cardBorderRadius = 12.0;
  static const double bottomSheetShadowOpacity = 0.05;
}

/// Worker employment types
class EmploymentType {
  const EmploymentType._();
  
  static const String fixed = 'FIXED';
  static const String hourly = 'HOURLY';
}
