import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart';

final payPeriodRepositoryProvider = Provider((ref) => PayPeriodRepository(ApiService()));

final payPeriodsProvider = AsyncNotifierProvider<PayPeriodsNotifier, List<PayPeriod>>(PayPeriodsNotifier.new);

class PayPeriodsNotifier extends AsyncNotifier<List<PayPeriod>> {
  late PayPeriodRepository _repository;

  @override
  FutureOr<List<PayPeriod>> build() {
    _repository = ref.watch(payPeriodRepositoryProvider);
    return _loadPayPeriods();
  }

  Future<List<PayPeriod>> _loadPayPeriods() async {
    final periods = await _repository.getPayPeriods();
    debugPrint('PayPeriodsNotifier: Loaded ${periods.length} periods');
    return periods;
  }

  /// Loads all pay periods (no status filter).
  /// Use for admin/overview screens.
  Future<void> loadPayPeriods() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPayPeriods());
  }

  /// Loads pay periods filtered by status.
  /// Use for dashboards or filtered views.
  Future<void> loadPayPeriodsByStatus(PayPeriodStatus status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getPayPeriodsByStatus(status));
  }

  Future<void> createPayPeriod(CreatePayPeriodRequest request) async {
    try {
      final newPayPeriod = await _repository.createPayPeriod(request);
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, newPayPeriod]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePayPeriod(String payPeriodId, UpdatePayPeriodRequest request) async {
    try {
      final updatedPayPeriod = await _repository.updatePayPeriod(payPeriodId, request);
      final payPeriods = state.value ?? [];
      final updatedPayPeriods = payPeriods.map((period) => period.id == payPeriodId ? updatedPayPeriod : period).toList();
      state = AsyncValue.data(updatedPayPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deletePayPeriod(String payPeriodId) async {
    try {
      await _repository.deletePayPeriod(payPeriodId);
      final payPeriods = state.value ?? [];
      final updatedPayPeriods = payPeriods.where((period) => period.id != payPeriodId).toList();
      state = AsyncValue.data(updatedPayPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> activatePayPeriod(String payPeriodId) async {
    try {
      await _repository.activatePayPeriod(payPeriodId);
      await loadPayPeriods(); // Reload to get updated data
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> processPayPeriod(String payPeriodId) async {
    try {
      await _repository.processPayPeriod(payPeriodId);
      await loadPayPeriods();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> completePayPeriod(String payPeriodId) async {
    try {
      await _repository.completePayPeriod(payPeriodId);
      await loadPayPeriods();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> closePayPeriod(String payPeriodId) async {
    try {
      await _repository.closePayPeriod(payPeriodId);
      await loadPayPeriods();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> reopenPayPeriod(String payPeriodId) async {
    try {
      await _repository.reopenPayPeriod(payPeriodId);
      await loadPayPeriods();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final payPeriodProvider = FutureProvider.family<PayPeriod, String>((ref, payPeriodId) async {
  final repository = ref.watch(payPeriodRepositoryProvider);
  return repository.getPayPeriodById(payPeriodId);
});

final currentPayPeriodProvider = FutureProvider<List<PayPeriod>>((ref) async {
  final repository = ref.watch(payPeriodRepositoryProvider);
  return repository.getCurrentPayPeriod();
});

final payPeriodsByStatusProvider = FutureProvider.family<List<PayPeriod>, PayPeriodStatus>((ref, status) async {
  final repository = ref.watch(payPeriodRepositoryProvider);
  return repository.getPayPeriodsByStatus(status);
});
