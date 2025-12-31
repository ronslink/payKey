import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tax_repository.dart';

class TaxPaymentsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  late TaxRepository _repository;
  
  @override
  FutureOr<Map<String, dynamic>> build() {
    _repository = ref.watch(taxRepositoryProvider);
    return _loadInitialSummary();
  }

  Future<Map<String, dynamic>> _loadInitialSummary() async {
      final now = DateTime.now();
      return _repository.getMonthlyTaxSummary(now.year, now.month);
  }

  Future<void> loadCurrentMonthSummary() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadInitialSummary());
  }

  Future<void> loadMonthlySummary(int year, int month) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getMonthlyTaxSummary(year, month));
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

final taxPaymentsProvider = AsyncNotifierProvider<TaxPaymentsNotifier, Map<String, dynamic>>(TaxPaymentsNotifier.new);

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