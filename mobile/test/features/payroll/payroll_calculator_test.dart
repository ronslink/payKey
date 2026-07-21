import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payroll/presentation/utils/payroll_calculator.dart';
import 'package:mobile/features/workers/data/models/worker_model.dart';

void main() {
  WorkerModel worker({
    double salaryGross = 32000,
    String employmentType = 'FIXED',
    double? hourlyRate,
  }) {
    return WorkerModel(
      id: 'worker-1',
      name: 'Test Worker',
      phoneNumber: '0700000000',
      salaryGross: salaryGross,
      isActive: true,
      employmentType: employmentType,
      hourlyRate: hourlyRate,
    );
  }

  group('PayrollCalculator gross-pay previews', () {
    test('returns the monthly salary for a full fixed-pay period', () {
      expect(PayrollCalculator.calculateEstimatedPay(worker: worker()), 32000);
    });

    test(
      'prorates fixed pay and adds overtime at the configured multiplier',
      () {
        final result = PayrollCalculator.calculateEstimatedPay(
          worker: worker(),
          prorationFactor: 0.5,
          overtime: 4,
        );

        // KES 16,000 prorated salary + 4 × KES 200 hourly rate × 1.5.
        expect(result, 17200);
      },
    );

    test('uses actual hours and overtime for hourly workers', () {
      final result = PayrollCalculator.calculateEstimatedPay(
        worker: worker(
          salaryGross: 0,
          employmentType: 'HOURLY',
          hourlyRate: 250,
        ),
        hours: 80,
        overtime: 6,
      );

      expect(result, 22250);
    });

    test('applies cash adjustments without calculating statutory deductions', () {
      final result = PayrollCalculator.calculateEstimatedPay(
        worker: worker(),
        bonuses: 3000,
        taxExemptAllowances: 1500,
        nonCashBenefits: 2000,
        deductions: 750,
      );

      // Non-cash benefits affect backend tax calculations, not the cash preview.
      expect(result, 35750);
    });
  });
}
