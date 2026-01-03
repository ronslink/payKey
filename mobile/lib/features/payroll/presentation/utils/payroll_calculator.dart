import '../../../workers/data/models/worker_model.dart';
import '../constants/payroll_constants.dart';

/// Utility for client-side payroll estimations
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
    double deductions = 0,
    double prorationFactor = 1.0,
  }) {
    double basePay = 0;
    final isHourly = worker.employmentType == EmploymentType.hourly;

    if (isHourly) {
      // Hourly workers: proration doesn't apply, they're paid for actual hours
      final hourlyRate = worker.hourlyRate ?? 0;
      basePay = (hours * hourlyRate) + (overtime * hourlyRate * PayrollConstants.overtimeMultiplier);
    } else {
      // For monthly workers, apply proration factor
      final monthlyRate = worker.salaryGross;
      final proratedMonthly = monthlyRate * prorationFactor;
      final hourlyRate = monthlyRate / PayrollConstants.defaultMonthlyHours;
      basePay = proratedMonthly + (overtime * hourlyRate * PayrollConstants.overtimeMultiplier);
    }

    // Apply adjustments
    // Note: Deductions here are manual "other deductions" (like loans), not tax
    return basePay + bonuses - deductions;
  }
  // ===========================================================================
  // TAX CONSTANTS (Kenya 2024/2025)
  // ===========================================================================
  static const double shifRate = 0.0275; // 2.75%
  static const double shifMinimum = 300;
  static const double housingLevyRate = 0.015; // 1.5%
  static const double nssfRate = 0.06; // 6%
  static const double nssfTierIUpperLimit = 6000;
  static const double nssfTierIIUpperLimit = 18000;
  static const double personalRelief = 2400;

  // ===========================================================================
  // CALCULATION METHODS
  // ===========================================================================

  /// Calculate NSSF Contribution (Tier I + Tier II)
  static double calculateNSSF(double grossSalary) {
    if (grossSalary <= 0) return 0;
    
    // Tier I
    final tierI_pensionable = grossSalary > nssfTierIUpperLimit 
        ? nssfTierIUpperLimit 
        : grossSalary;
    final tierI = tierI_pensionable * nssfRate;
    
    // Tier II
    double tierII = 0;
    if (grossSalary > nssfTierIUpperLimit) {
      final remainder = grossSalary - nssfTierIUpperLimit;
      final tierII_pensionable = (grossSalary > nssfTierIIUpperLimit)
          ? (nssfTierIIUpperLimit - nssfTierIUpperLimit)
          : remainder;
      tierII = tierII_pensionable * nssfRate;
    }

    return tierI + tierII;
  }

  /// Calculate SHIF Deduction (Social Health Insurance Fund)
  /// Rate: 2.75% of Gross Salary
  /// Minimum: KES 300
  static double calculateSHIF(double grossSalary) {
    if (grossSalary <= 0) return 0;
    
    final shif = grossSalary * shifRate;
    return shif < shifMinimum ? shifMinimum : shif;
  }

  /// Calculate Housing Levy (1.5% of Gross)
  static double calculateHousingLevy(double grossSalary) {
    return grossSalary * housingLevyRate;
  }

  /// Calculate PAYE (Pay As You Earn)
  /// Based on Taxable Income (Gross - NSSF)
  /// Note: SHIF/HousingLevy are NOT tax deductible for PAYE base (Insurance Relief applies after tax)
  /// Current Simplified: We are not applying Insurance Relief for SHIF yet unless specified.
  static double calculatePAYE(double grossSalary) {
    final nssf = calculateNSSF(grossSalary);
    final taxableIncome = grossSalary - nssf;
    
    if (taxableIncome <= 24000) return 0; // Below tax threshold due to relief

    double tax = 0;
    double remaining = taxableIncome;

    // Band 1: First 24,000 @ 10%
    if (remaining > 0) {
      final band = 24000.0;
      final amount = remaining > band ? band : remaining;
      tax += amount * 0.10;
      remaining -= amount;
    }

    // Band 2: Next 8,333 @ 25% (up to 32,333)
    if (remaining > 0) {
      final band = 8333.0;
      final amount = remaining > band ? band : remaining;
      tax += amount * 0.25;
      remaining -= amount;
    }

    // Band 3: Next 467,667 @ 30% (up to 500,000)
    if (remaining > 0) {
      final band = 467667.0;
      final amount = remaining > band ? band : remaining;
      tax += amount * 0.30;
      remaining -= amount;
    }

    // Band 4: Over 500,000 @ 32.5%
    if (remaining > 0) {
      final band = 300000.0; // Next 300k
      final amount = remaining > band ? band : remaining;
      tax += amount * 0.325;
      remaining -= amount;
    }
    
    // Band 5: Over 800,000 @ 35%
    if (remaining > 0) {
       tax += remaining * 0.35;
    }

    // Apply Personal Relief
    var finalTax = tax - personalRelief;
    
    // Apply Insurance Relief (15% of SHIF contribution)
    // SHIF is treated as an insurance contribution eligible for relief
    final shif = calculateSHIF(grossSalary);
    final insuranceRelief = shif * 0.15;
    finalTax -= insuranceRelief;

    return finalTax > 0 ? finalTax : 0;
  }

  /// Calculate Net Estimated Pay
  static double calculateNetPay(double grossSalary) {
    final paye = calculatePAYE(grossSalary);
    final shif = calculateSHIF(grossSalary);
    final nssf = calculateNSSF(grossSalary);
    final housingLevy = calculateHousingLevy(grossSalary);
    
    return grossSalary - paye - shif - nssf - housingLevy;
  }
}

