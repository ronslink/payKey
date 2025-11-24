import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tax_submission_model.dart';
import '../../data/repositories/tax_repository.dart';

final taxRepositoryProvider = Provider((ref) => TaxRepository());

final taxSubmissionsProvider = FutureProvider<List<TaxSubmissionModel>>((ref) async {
  final repository = ref.watch(taxRepositoryProvider);
  return repository.getTaxSubmissions();
});

class TaxNotifier extends StateNotifier<AsyncValue<List<TaxSubmissionModel>>> {
  final TaxRepository _repository;

  TaxNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    state = const AsyncValue.loading();
    try {
      final submissions = await _repository.getTaxSubmissions();
      state = AsyncValue.data(submissions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsFiled(String id) async {
    try {
      await _repository.markAsFiled(id);
      await loadSubmissions(); // Refresh the list
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, double>> calculateTax(double grossSalary) async {
    try {
      return await _repository.calculateTax(grossSalary);
    } catch (e, st) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentTaxTable() async {
    try {
      return await _repository.getCurrentTaxTable();
    } catch (e, st) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      return await _repository.getComplianceStatus();
    } catch (e, st) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTaxDeadlines() async {
    try {
      return await _repository.getTaxDeadlines();
    } catch (e, st) {
      rethrow;
    }
  }
}

final taxNotifierProvider = StateNotifierProvider<TaxNotifier, AsyncValue<List<TaxSubmissionModel>>>((ref) {
  final repository = ref.watch(taxRepositoryProvider);
  return TaxNotifier(repository);
});
