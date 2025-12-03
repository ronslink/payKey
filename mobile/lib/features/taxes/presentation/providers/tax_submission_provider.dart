import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tax_repository.dart';
import '../../data/models/tax_submission_model.dart';

class TaxSubmissionNotifier extends StateNotifier<AsyncValue<List<TaxSubmissionModel>>> {
  final TaxRepository _repository;

  TaxSubmissionNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadSubmissions({
    String? taxYear,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      state = const AsyncValue.loading();
      final result = await _repository.getIndividualTaxSubmissions();
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitTaxReturn(TaxSubmissionModel submission) async {
    try {
      await _repository.submitTaxReturn(submission);
      await loadSubmissions();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsFiled(String submissionId) async {
    try {
      await _repository.markIndividualTaxAsFiled(submissionId);
      await loadSubmissions();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<TaxSubmissionModel>> calculateTax(double income, double deductions) async {
    try {
      final calculationResult = await _repository.calculateTax(income, deductions);
      // Convert the calculation result to a TaxSubmissionModel
      final tax = calculationResult['taxAmount'] ?? 0.0;
      return [
        TaxSubmissionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'current-user',
          taxYear: DateTime.now().year.toString(),
          income: income,
          deductions: deductions,
          taxableIncome: calculationResult['taxableIncome'] ?? (income - deductions),
          taxDue: tax,
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      return await _repository.getComplianceStatus();
    } catch (error) {
      throw Exception('Failed to get compliance status: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getTaxDeadlines() async {
    try {
      return await _repository.getTaxDeadlines();
    } catch (error) {
      throw Exception('Failed to get tax deadlines: $error');
    }
  }
}

// Provider for individual tax submissions (NOT payroll-related)
final taxSubmissionProvider =
    StateNotifierProvider<TaxSubmissionNotifier, AsyncValue<List<TaxSubmissionModel>>>((ref) {
  final repository = ref.read(taxRepositoryProvider);
  return TaxSubmissionNotifier(repository);
});

// Helper provider for tax calculations
final taxCalculatorProvider =
    Provider((ref) => (double income, double deductions) async {
      final notifier = ref.read(taxSubmissionProvider.notifier);
      return await notifier.calculateTax(income, deductions);
    });

// Helper provider for compliance status
final taxComplianceProvider =
    Provider((ref) => () async {
      final notifier = ref.read(taxSubmissionProvider.notifier);
      return await notifier.getComplianceStatus();
    });

// Helper provider for tax deadlines
final taxDeadlinesProvider =
    Provider((ref) => () async {
      final notifier = ref.read(taxSubmissionProvider.notifier);
      return await notifier.getTaxDeadlines();
    });