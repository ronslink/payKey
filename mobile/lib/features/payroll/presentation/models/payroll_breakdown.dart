import '../../data/models/payroll_model.dart';

/// Represents a complete payroll breakdown for a single worker
/// 
/// Contains all earnings, statutory deductions, and net pay calculation.
/// Immutable for easy testing and caching.
class PayrollBreakdown {
  final double grossSalary;
  final double nssfContribution;
  final double nhifContribution;
  final double housingLevy;
  final double taxableIncome;
  final double paye;
  final double otherDeductions;
  final double otherEarnings;
  final double netSalary;

  const PayrollBreakdown({
    required this.grossSalary,
    required this.nssfContribution,
    required this.nhifContribution,
    required this.housingLevy,
    required this.taxableIncome,
    required this.paye,
    this.otherDeductions = 0,
    this.otherEarnings = 0,
    required this.netSalary,
  });

  /// Total statutory deductions (NSSF + NHIF + Housing Levy + PAYE)
  double get statutoryDeductions => 
      nssfContribution + nhifContribution + housingLevy + paye;

  /// Total all deductions including other deductions
  double get totalDeductions => statutoryDeductions + otherDeductions;

  /// Total earnings (gross + other earnings)
  double get totalEarnings => grossSalary + otherEarnings;

  /// Create an empty breakdown (for error states)
  const PayrollBreakdown.empty()
      : grossSalary = 0,
        nssfContribution = 0,
        nhifContribution = 0,
        housingLevy = 0,
        taxableIncome = 0,
        paye = 0,
        otherDeductions = 0,
        otherEarnings = 0,
        netSalary = 0;

  /// Creates a breakdown from a backend calculation.
  factory PayrollBreakdown.fromCalculation(PayrollCalculation calc) {
    return PayrollBreakdown(
      grossSalary: calc.grossSalary,
      nssfContribution: calc.taxBreakdown.nssf,
      nhifContribution: calc.taxBreakdown.nhif,
      housingLevy: calc.taxBreakdown.housingLevy,
      // Backend doesn't explicitly send taxable income, usually Gross - NSSF
      // But we just use it for display if needed.
      taxableIncome: calc.grossSalary - calc.taxBreakdown.nssf, 
      paye: calc.taxBreakdown.paye,
      otherDeductions: calc.otherDeductions,
      otherEarnings: calc.otherEarnings + calc.bonuses,
      netSalary: calc.netPay,
    );
  }

  /// Create a totals breakdown from a list of breakdowns
  factory PayrollBreakdown.totals(List<PayrollBreakdown> breakdowns) {
    if (breakdowns.isEmpty) return const PayrollBreakdown.empty();

    double totalGross = 0;
    double totalNssf = 0;
    double totalNhif = 0;
    double totalHousing = 0;
    double totalPaye = 0;
    double totalOtherDeductions = 0;
    double totalOtherEarnings = 0;
    double totalNet = 0;

    for (final b in breakdowns) {
      totalGross += b.grossSalary;
      totalNssf += b.nssfContribution;
      totalNhif += b.nhifContribution;
      totalHousing += b.housingLevy;
      totalPaye += b.paye;
      totalOtherDeductions += b.otherDeductions;
      totalOtherEarnings += b.otherEarnings;
      totalNet += b.netSalary;
    }

    return PayrollBreakdown(
      grossSalary: totalGross,
      nssfContribution: totalNssf,
      nhifContribution: totalNhif,
      housingLevy: totalHousing,
      taxableIncome: totalGross - totalNssf,
      paye: totalPaye,
      otherDeductions: totalOtherDeductions,
      otherEarnings: totalOtherEarnings,
      netSalary: totalNet,
    );
  }

  @override
  String toString() => 'PayrollBreakdown(gross: $grossSalary, net: $netSalary)';
}
