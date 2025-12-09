import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_period_repository.dart';

final payPeriodRepositoryProvider = Provider((ref) => PayPeriodRepository(ApiService()));

final payPeriodsProvider = StateNotifierProvider<PayPeriodsNotifier, AsyncValue<List<PayPeriod>>>((ref) {
  final repository = ref.read(payPeriodRepositoryProvider);
  return PayPeriodsNotifier(repository);
});

class PayPeriodsNotifier extends StateNotifier<AsyncValue<List<PayPeriod>>> {
  final PayPeriodRepository _repository;

  PayPeriodsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPayPeriods();
  }

  /// Loads all pay periods (no status filter).
  /// Use for admin/overview screens.
  Future<void> loadPayPeriods() async {
    try {
      state = const AsyncValue.loading();
      final payPeriods = await _repository.getPayPeriods();
      state = AsyncValue.data(payPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Loads pay periods filtered by status.
  /// Use for dashboards or filtered views.
  Future<void> loadPayPeriodsByStatus(PayPeriodStatus status) async {
    try {
      state = const AsyncValue.loading();
      final payPeriods = await _repository.getPayPeriodsByStatus(status);
      state = AsyncValue.data(payPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createPayPeriod(CreatePayPeriodRequest request) async {
    try {
      final newPayPeriod = await _repository.createPayPeriod(request);
      state = AsyncValue.data([
        ...?state.value,
        newPayPeriod,
      ]);
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
  final repository = ref.read(payPeriodRepositoryProvider);
  return repository.getPayPeriodById(payPeriodId);
});

final currentPayPeriodProvider = FutureProvider<List<PayPeriod>>((ref) async {
  final repository = ref.read(payPeriodRepositoryProvider);
  return repository.getCurrentPayPeriod();
});

final payPeriodsByStatusProvider = FutureProvider.family<List<PayPeriod>, PayPeriodStatus>((ref, status) async {
  final repository = ref.read(payPeriodRepositoryProvider);
  return repository.getPayPeriodsByStatus(status);
});
