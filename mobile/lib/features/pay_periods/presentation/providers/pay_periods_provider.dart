import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pay_period_model.dart';
import '../../data/repositories/pay_periods_repository.dart';

class PayPeriodsNotifier extends StateNotifier<AsyncValue<List<PayPeriodModel>>> {
  final PayPeriodsRepositoryImpl _repository;

  PayPeriodsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPayPeriods();
  }

  Future<void> loadPayPeriods({
    int page = 1,
    int limit = 10,
    PayPeriodStatus? status,
    PayPeriodFrequency? frequency,
  }) async {
    try {
      state = const AsyncValue.loading();
      final payPeriods = await _repository.getPayPeriods(
        page: page,
        limit: limit,
        status: status,
        frequency: frequency,
      );
      state = AsyncValue.data(payPeriods);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<PayPeriodModel?> createPayPeriod({
    required String name,
    required String startDate,
    required String endDate,
    String? payDate,
    required PayPeriodFrequency frequency,
    Map<String, dynamic>? notes,
  }) async {
    try {
      final newPayPeriod = await _repository.createPayPeriod(
        name: name,
        startDate: startDate,
        endDate: endDate,
        payDate: payDate,
        frequency: frequency,
        notes: notes,
      );

      // Refresh the list after creation
      state = state.whenData((payPeriods) => [newPayPeriod, ...payPeriods]);
      return newPayPeriod;
    } catch (error) {
      // Handle error (could show snackbar, etc.)
      return null;
    }
  }

  Future<bool> updatePayPeriod(
    String id, {
    String? name,
    String? startDate,
    String? endDate,
    String? payDate,
    PayPeriodStatus? status,
    String? approvedBy,
    Map<String, dynamic>? notes,
  }) async {
    try {
      final updatedPayPeriod = await _repository.updatePayPeriod(
        id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        payDate: payDate,
        status: status,
        approvedBy: approvedBy,
        notes: notes,
      );

      // Update the list with the modified pay period
      state = state.whenData((payPeriods) => payPeriods.map((pp) {
        return pp.id == id ? updatedPayPeriod : pp;
      }).toList());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> deletePayPeriod(String id) async {
    try {
      await _repository.deletePayPeriod(id);
      
      // Remove from the list
      state = state.whenData((payPeriods) => 
          payPeriods.where((pp) => pp.id != id).toList());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> activatePayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.activatePayPeriod(id);
      state = state.whenData((payPeriods) => payPeriods.map((pp) {
        return pp.id == id ? updatedPayPeriod : pp;
      }).toList());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> processPayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.processPayPeriod(id);
      state = state.whenData((payPeriods) => payPeriods.map((pp) {
        return pp.id == id ? updatedPayPeriod : pp;
      }).toList());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> completePayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.completePayPeriod(id);
      state = state.whenData((payPeriods) => payPeriods.map((pp) {
        return pp.id == id ? updatedPayPeriod : pp;
      }).toList());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> closePayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.closePayPeriod(id);
      state = state.whenData((payPeriods) => payPeriods.map((pp) {
        return pp.id == id ? updatedPayPeriod : pp;
      }).toList());
      return true;
    } catch (error) {
      return false;
    }
  }
}

// Provider for the notifier
final payPeriodsProvider = StateNotifierProvider<PayPeriodsNotifier, AsyncValue<List<PayPeriodModel>>>((ref) {
  final repository = ref.watch(payPeriodsRepositoryProvider);
  return PayPeriodsNotifier(repository);
});

// Helper provider for filtered pay periods
final filteredPayPeriodsProvider = Provider<AsyncValue<List<PayPeriodModel>>>((ref) {
  final payPeriodsState = ref.watch(payPeriodsProvider);
  return payPeriodsState;
});

// Single pay period provider
final payPeriodProvider = Provider.family<AsyncValue<PayPeriodModel>, String>((ref, id) {
  final payPeriodsState = ref.watch(payPeriodsProvider);
  
  return payPeriodsState.when(
    data: (payPeriods) {
      try {
        return AsyncValue.data(
          payPeriods.firstWhere((pp) => pp.id == id),
        );
      } catch (e) {
        return const AsyncValue.loading();
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Statistics provider
final payPeriodStatisticsProvider = Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, id) {
  return const AsyncValue.loading(); // You would implement loading logic here
});
