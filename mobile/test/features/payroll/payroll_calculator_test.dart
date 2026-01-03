
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payroll/presentation/utils/payroll_calculator.dart';


void main() {
  group('PayrollCalculator Unit Tests', () {
    
    // =========================================================================
    // NSSF TESTS
    // =========================================================================
    test('calculateNSSF - Lower Tier I only', () {
      // 6000 * 6% = 360
      expect(PayrollCalculator.calculateNSSF(6000), 360);
    });

    test('calculateNSSF - Between Tiers', () {
      // Gross 10,000
      // Tier I: 6000 * 6% = 360
      // Tier II: (10000 - 6000) = 4000 * 6% = 240
      // Total: 600
      expect(PayrollCalculator.calculateNSSF(10000), 600);
    });

    test('calculateNSSF - Max Tier II', () {
      // Gross 30,000 (Above 18,000 limit)
      // Tier I: 6000 * 6% = 360
      // Tier II: (18000 - 6000) = 12000 * 6% = 720
      // Total: 1080
      expect(PayrollCalculator.calculateNSSF(30000), 1080);
    });

    // =========================================================================
    // SHIF TESTS (Social Health Insurance Fund)
    // Rate: 2.75% of Gross, Min 300
    // =========================================================================
    test('calculateSHIF - Minimum Contribution', () {
      // Gross 6,000 * 2.75% = 165
      // Minimal is 300, so expect 300
      expect(PayrollCalculator.calculateSHIF(6000), 300);
    });

    test('calculateSHIF - Standard Calculation', () {
      // Gross 50,000 * 2.75% = 1375
      expect(PayrollCalculator.calculateSHIF(50000), 1375);
    });

    // =========================================================================
    // HOUSING LEVY TESTS
    // =========================================================================
    test('calculateHousingLevy', () {
      // 100,000 * 1.5% = 1500
      expect(PayrollCalculator.calculateHousingLevy(100000), 1500);
    });

    // =========================================================================
    // PAYE TESTS
    // =========================================================================
    test('calculatePAYE - Below Taxable Threshold', () {
      // Gross 24,000
      // NSSF = 1080 (capped)
      // Taxable = 22,920
      // Below 24,000 -> Tax 0
      expect(PayrollCalculator.calculatePAYE(24000), 0);
    });

    test('calculatePAYE - With Insurance Relief (Standard Case)', () {
      // Gross 50,000
      // NSSF = 1080 (capped)
      // Taxable Income = 48,920
      
      // TAX CALC:
      // Band 1: 24,000 @ 10% = 2,400
      // Band 2: 8,333 @ 25% = 2,083.25
      // Band 3: (48,920 - 32,333) = 16,587 @ 30% = 4,976.1
      // Total Tax = 2400 + 2083.25 + 4976.1 = 9,459.35
      
      // RELIEF:
      // Personal Relief = 2,400
      // SHIF = 50,000 * 2.75% = 1,375
      // Insurance Relief = 1,375 * 15% = 206.25
      // Total Relief = 2,606.25
      
      // PAYE = 9,459.35 - 2,606.25 = 6,853.1
      
      // Checking for reasonable approximation due to float precision
      final paye = PayrollCalculator.calculatePAYE(50000);
      expect(paye, closeTo(6853.1, 0.1));
    });

    // =========================================================================
    // NET PAY TESTS
    // =========================================================================
    test('calculateNetPay - Simple Case', () {
      // Gross 6000
      // NSSF: 360
      // SHIF: 300 (min)
      // Housing Levy: 6000 * 1.5% = 90
      // PAYE: 0 (Taxable 5640 < 24000)
      // Deductions: 360 + 300 + 90 = 750
      // Net: 5250
      expect(PayrollCalculator.calculateNetPay(6000), 5250);
    });
  });
}
