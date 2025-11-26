import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tax_repository.dart';

class TaxPaymentsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final TaxRepository _repository;
  
  TaxPaymentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCurrentMonthSummary();
  }

  Future<void> loadCurrentMonthSummary() async {
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now();
      final summary = await _repository.getMonthlyTaxSummary(now.year, now.month);
      state = AsyncValue.data(summary);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMonthlySummary(int year, int month) async {
    try {
      state = const AsyncValue.loading();
      final summary = await _repository.getMonthlyTaxSummary(year, month);
      state = AsyncValue.data(summary);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> recordPayment(Map<String, dynamic> paymentData) async {
    try {
      await _repository.recordTaxPayment(paymentData);
      // Refresh summary after recording payment
      await loadCurrentMonthSummary();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    return _repository.getTaxPaymentHistory();
  }

  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    return _repository.getPendingTaxPayments();
  }

  Future<void> updatePaymentStatus(String id, String status) async {
    await _repository.updateTaxPaymentStatus(id, status);
    // Refresh summary after updating status
    await loadCurrentMonthSummary();
  }

  Future<Map<String, dynamic>> getPaymentInstructions() async {
    return _repository.getTaxPaymentInstructions();
  }
}

final taxPaymentsProvider = StateNotifierProvider<TaxPaymentsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final repository = ref.read(taxRepositoryProvider);
  return TaxPaymentsNotifier(repository);
});

final taxPaymentHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.read(taxRepositoryProvider);
  return repository.getTaxPaymentHistory();
});

final pendingTaxPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.read(taxRepositoryProvider);
  return repository.getPendingTaxPayments();
});

final taxPaymentInstructionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(taxRepositoryProvider);
  return repository.getTaxPaymentInstructions();
});