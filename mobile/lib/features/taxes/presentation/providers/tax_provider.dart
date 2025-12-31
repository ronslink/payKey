import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_tax_submission.dart';
import '../../data/models/tax_submission_model.dart';
import '../../data/models/monthly_tax_summary.dart';
import '../../data/repositories/tax_repository.dart';

final taxRepositoryProvider = Provider((ref) => TaxRepository());

// Provider for individual tax submissions (personal/business tax returns)
final individualTaxSubmissionsProvider = FutureProvider<List<TaxSubmissionModel>>((ref) async {
  final repository = ref.watch(taxRepositoryProvider);
  return repository.getIndividualTaxSubmissions();
});

// Provider for payroll tax submissions (auto-generated from payroll)
final payrollTaxSubmissionsProvider = FutureProvider<List<PayrollTaxSubmission>>((ref) async {
  final repository = ref.watch(taxRepositoryProvider);
  return repository.getPayrollTaxSubmissions();
});


// Removed unused IndividualTaxNotifier and PayrollTaxNotifier

final monthlyTaxSummariesProvider = AsyncNotifierProvider<MonthlyTaxNotifier, List<MonthlyTaxSummary>>(MonthlyTaxNotifier.new);

class MonthlyTaxNotifier extends AsyncNotifier<List<MonthlyTaxSummary>> {
  late TaxRepository _repository;

  @override
  FutureOr<List<MonthlyTaxSummary>> build() {
    _repository = ref.watch(taxRepositoryProvider);
    return _loadSummaries();
  }

  Future<List<MonthlyTaxSummary>> _loadSummaries() {
    return _repository.getMonthlyTaxSummaries();
  }

  Future<void> markMonthAsFiled(int year, int month) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.markMonthAsFiled(year, month);
      return _loadSummaries();
    });
  }

  Future<void> loadSummaries() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadSummaries());
  }

  Future<List<int>> downloadReturn(String exportType, int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      final endDate = DateTime(year, month, daysInMonth, 23, 59, 59);

      final exportId = await _repository.downloadStatutoryReturn(exportType, startDate, endDate);
      final bytes = await _repository.getExportFile(exportId);
      return bytes;
    } catch (e) {
      // Don't update state here as this is a download action
      rethrow;
    }
  }
}

// Backward compatibility notifier
class TaxNotifier extends AsyncNotifier<List<dynamic>> {
  late TaxRepository _repository;

  @override
  FutureOr<List<dynamic>> build() {
    _repository = ref.watch(taxRepositoryProvider);
    return _loadSubmissions();
  }

  Future<List<dynamic>> _loadSubmissions() {
    return _repository.getPayrollTaxSubmissions();
  }

  Future<void> markAsFiled(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.markIndividualTaxAsFiled(id);
      return _loadSubmissions();
    });
  }

  Future<List<TaxSubmissionModel>> calculateTax(double grossSalary) async {
    try {
      final taxCalculation = await _repository.calculatePayrollTax(grossSalary);
      
      final result = TaxSubmissionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current-user',
        taxYear: DateTime.now().year.toString(),
        income: grossSalary,
        deductions: taxCalculation['totalDeductions'] ?? 0.0,
        taxableIncome: grossSalary - (taxCalculation['totalDeductions'] ?? 0.0),
        taxDue: taxCalculation['paye'] ?? 0.0,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return [result];
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getComplianceStatus() async {
    return await _repository.getComplianceStatus();
  }

  Future<void> generateTaxSubmission(String payPeriodId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.generateTaxSubmission(payPeriodId);
      return _loadSubmissions();
    });
  }

  Future<List<Map<String, dynamic>>> getTaxDeadlines() async {
    return [
      {
        'title': 'Annual Tax Return',
        'description': 'Submit your annual tax return',
        'dueDate': '2024-04-30',
      },
    ];
  }
}

final taxNotifierProvider = AsyncNotifierProvider<TaxNotifier, List<dynamic>>(TaxNotifier.new);

// Tax calculator provider
final taxCalculatorProvider = Provider<Future<List<TaxSubmissionModel>> Function(double, double)>((ref) {
  return (double income, double deductions) async {
    final tax = (income - deductions) * 0.3;
    return [
      TaxSubmissionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current-user',
        taxYear: DateTime.now().year.toString(),
        income: income,
        deductions: deductions,
        taxableIncome: income - deductions,
        taxDue: tax,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  };
});
