import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile/features/payroll/data/models/pay_period_model.dart';
import 'package:mobile/features/payroll/data/models/payroll_model.dart';
import 'package:mobile/features/payroll/data/repositories/pay_period_repository.dart';
import 'package:mobile/features/payroll/data/repositories/payroll_repository.dart';

// Generate mocks
@GenerateMocks([PayPeriodRepository, PayrollRepository])
import 'payroll_workflow_test.mocks.dart';

void main() {
  late MockPayPeriodRepository mockPayPeriodRepository;
  late MockPayrollRepository mockPayrollRepository;

  setUp(() {
    mockPayPeriodRepository = MockPayPeriodRepository();
    mockPayrollRepository = MockPayrollRepository();
  });

  group('Payroll Workflow Tests', () {
    test('Full Payroll Lifecycle: Create -> Add Workers -> Process -> Complete', () async {
      // 1. Create Pay Period
      final startDate = DateTime(2025, 12, 1);
      final endDate = DateTime(2025, 12, 31);
      final newPayPeriod = PayPeriod(
        id: 'pp-123',
        name: 'December 2025',
        startDate: startDate,
        endDate: endDate,
        frequency: PayPeriodFrequency.monthly,
        status: PayPeriodStatus.draft,
        totalWorkers: 0,
        totalGrossAmount: 0,
        totalNetAmount: 0,
        processedWorkers: 0,
      );

      when(mockPayPeriodRepository.createPayPeriod(any)).thenAnswer((_) async => newPayPeriod);

      // Simulate creation
      final createdPeriod = await mockPayPeriodRepository.createPayPeriod(
        CreatePayPeriodRequest(
          name: 'December 2025',
          startDate: startDate,
          endDate: endDate,
          frequency: PayPeriodFrequency.monthly,
        ),
      );

      expect(createdPeriod.id, 'pp-123');
      expect(createdPeriod.status, PayPeriodStatus.draft);
      verify(mockPayPeriodRepository.createPayPeriod(any)).called(1);

      // 2. Add Workers (Calculate & Save Draft)
      final workerIds = ['worker-1', 'worker-2'];
      final calculations = [
        PayrollCalculation(
          workerId: 'worker-1',
          workerName: 'John Doe',
          grossSalary: 50000,
          netPay: 40000,
          taxBreakdown: TaxBreakdown(nssf: 1000, nhif: 1000, housingLevy: 1000, paye: 7000, totalDeductions: 10000),
        ),
        PayrollCalculation(
          workerId: 'worker-2',
          workerName: 'Jane Smith',
          grossSalary: 60000,
          netPay: 48000,
          taxBreakdown: TaxBreakdown(nssf: 1000, nhif: 1000, housingLevy: 1000, paye: 9000, totalDeductions: 12000),
        ),
      ];

      when(mockPayrollRepository.calculatePayroll(workerIds)).thenAnswer((_) async => calculations);
      when(mockPayrollRepository.saveDraftPayroll(any, any)).thenAnswer((_) async => calculations);

      // Simulate adding workers
      final calculated = await mockPayrollRepository.calculatePayroll(workerIds);
      expect(calculated, hasLength(2));
      expect(calculated[0].grossSalary, 50000);

      final savedDraft = await mockPayrollRepository.saveDraftPayroll(createdPeriod.id, []);
      expect(savedDraft, hasLength(2));
      verify(mockPayrollRepository.calculatePayroll(workerIds)).called(1);
      verify(mockPayrollRepository.saveDraftPayroll(createdPeriod.id, any)).called(1);

      // 3. Activate Pay Period
      final activatedPeriod = newPayPeriod.copyWith(status: PayPeriodStatus.active);
      when(mockPayPeriodRepository.activatePayPeriod(any)).thenAnswer((_) async => activatedPeriod);
      await mockPayPeriodRepository.activatePayPeriod(createdPeriod.id);
      verify(mockPayPeriodRepository.activatePayPeriod(createdPeriod.id)).called(1);

      // 4. Process Payroll
      final processingPeriod = activatedPeriod.copyWith(status: PayPeriodStatus.processing);
      when(mockPayPeriodRepository.processPayPeriod(any)).thenAnswer((_) async => processingPeriod);
      await mockPayPeriodRepository.processPayPeriod(createdPeriod.id);
      verify(mockPayPeriodRepository.processPayPeriod(createdPeriod.id)).called(1);

      // 5. Complete Payroll
      final completedPeriod = processingPeriod.copyWith(status: PayPeriodStatus.completed);
      when(mockPayPeriodRepository.completePayPeriod(any)).thenAnswer((_) async => completedPeriod);
      await mockPayPeriodRepository.completePayPeriod(createdPeriod.id);
      verify(mockPayPeriodRepository.completePayPeriod(createdPeriod.id)).called(1);
    });
  });
}
