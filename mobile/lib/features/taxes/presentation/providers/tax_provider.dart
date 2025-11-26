import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_tax_submission.dart';
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

class IndividualTaxNotifier extends StateNotifier<AsyncValue<List<TaxSubmissionModel>>> {
  final TaxRepository _repository;

  IndividualTaxNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    state = const AsyncValue.loading();
    try {
      final submissions = await _repository.getIndividualTaxSubmissions();
      state = AsyncValue.data(submissions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsFiled(String id) async {
    try {
      await _repository.markAsFiled(id);
      await loadSubmissions(); // Reload data
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PayrollTaxNotifier extends StateNotifier<AsyncValue<List<PayrollTaxSubmission>>> {
  final TaxRepository _repository;

  PayrollTaxNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    state = const AsyncValue.loading();
    try {
      final submissions = await _repository.getPayrollTaxSubmissions();
      state = AsyncValue.data(submissions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsFiled(String id) async {
    try {
      await _repository.markPayrollTaxAsFiled(id);
      await loadSubmissions(); // Refresh the list
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, double>> calculateTax(double grossSalary) async {
    try {
      return await _repository.calculateTax(grossSalary, 0); // Simplified with no deductions
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentTaxTable() async {
    try {
      return await _repository.getCurrentTaxTable();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      return await _repository.getComplianceStatus();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTaxDeadlines() async {
    try {
      return await _repository.getTaxDeadlines();
    } catch (e) {
      rethrow;
    }
  }
}

// Backward compatibility notifier
class TaxNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final TaxRepository _repository;

  TaxNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    state = const AsyncValue.loading();
    try {
      // Load individual tax submissions for backward compatibility
      final submissions = await _repository.getIndividualTaxSubmissions();
      state = AsyncValue.data(submissions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsFiled(String id) async {
    try {
      await _repository.markIndividualTaxAsFiled(id);
      await loadSubmissions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
Future<List<TaxSubmissionModel>> calculateTax(double grossSalary) async {
  try {
    // Use backend API for proper tax calculations (PAYE, NSSF, SHIF, Housing Levy)
    final taxCalculation = await _repository.calculatePayrollTax(grossSalary);
    
    final result = TaxSubmissionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current-user',
      taxYear: DateTime.now().year.toString(),
      income: grossSalary,
      deductions: taxCalculation['totalDeductions'] ?? 0.0,
      taxableIncome: grossSalary - (taxCalculation['totalDeductions'] ?? 0.0),
      taxDue: taxCalculation['paye'] ?? 0.0, // Use PAYE from backend
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
    return {
      'kraPin': true,
      'nssf': true,
      'nhif': true,
      'status': 'compliant',
      'nextFilingDate': '2024-04-30',
    };
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
