
class PayrollUtils {
  /// Safely parse a dynamic value to double.
  /// Handles num types and String representations.
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parse total deductions from a payroll record map.
  /// Prioritizes explicit 'taxBreakdown.totalDeductions', then falls back to 'Gross - Net', then 'taxAmount'.
  static double parseDeductions(Map<String, dynamic> map) {
    // Try to get explicit totalDeductions from taxBreakdown
    try {
      if (map['taxBreakdown'] != null) {
        final breakdown = map['taxBreakdown'];
        if (breakdown is Map && breakdown['totalDeductions'] != null) {
          return parseDouble(breakdown['totalDeductions']);
        }
      }
    } catch (_) {}

    // Fallback: Gross - Net
    final gross = parseDouble(map['grossSalary']);
    final net = parseDouble(map['netSalary']);
    if (gross > net) return gross - net;

    // Fallback: just Tax Amount (PAYE) which might be 0
    return parseDouble(map['taxAmount']);
  }
}
