import '../../../workers/data/models/worker_model.dart';
import '../constants/payroll_constants.dart';

/// Utility for gross-pay previews only.
///
/// Statutory deductions are intentionally calculated by the backend from
/// effective-dated Kenya tax configuration. Keeping tax rates out of the app
/// prevents an older mobile release from producing a conflicting payslip.
class PayrollCalculator {
  const PayrollCalculator._();

  /// Calculate estimated pay based on hours and overtime
  ///
  /// This is an ESTIMATE for UI display only.
  /// Final calculations are done server-side.
  ///
  /// [prorationFactor] should be daysWorked / totalDaysInPeriod for partial months
  static double calculateEstimatedPay({
    required WorkerModel worker,
    double hours = 0,
    double overtime = 0,
    double bonuses = 0,
    double taxExemptAllowances = 0,
    double nonCashBenefits = 0, // Used for tax, but excluded in net cash.
    double deductions = 0,
    double prorationFactor = 1.0,
  }) {
    double basePay = 0;
    final isHourly = worker.employmentType == EmploymentType.hourly;

    if (isHourly) {
      // Hourly workers: proration doesn't apply, they're paid for actual hours
      final hourlyRate = worker.hourlyRate ?? 0;
      basePay =
          (hours * hourlyRate) +
          (overtime * hourlyRate * PayrollConstants.overtimeMultiplier);
    } else {
      // For monthly workers, apply proration factor
      final monthlyRate = worker.salaryGross;
      final proratedMonthly = monthlyRate * prorationFactor;
      final hourlyRate = monthlyRate / PayrollConstants.defaultMonthlyHours;
      basePay =
          proratedMonthly +
          (overtime * hourlyRate * PayrollConstants.overtimeMultiplier);
    }

    // Apply adjustments
    // Note: Deductions here are manual "other deductions" (like loans), not tax
    return basePay + bonuses + taxExemptAllowances - deductions;
  }
}
