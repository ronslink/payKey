import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Use the canonical Freezed-based PayPeriod model
import '../../../payroll/data/models/pay_period_model.dart';
import '../../data/repositories/pay_periods_repository.dart';

final payPeriodsProvider = AsyncNotifierProvider<PayPeriodsNotifier, List<PayPeriod>>(PayPeriodsNotifier.new);

class PayPeriodsNotifier extends AsyncNotifier<List<PayPeriod>> {
  late final PayPeriodsRepositoryImpl _repository;

  @override
  FutureOr<List<PayPeriod>> build() {
    _repository = ref.watch(payPeriodsRepositoryProvider);
    return _loadPayPeriods();
  }

  Future<List<PayPeriod>> _loadPayPeriods({
    int page = 1,
    int limit = 100,  // Load all periods by default
    PayPeriodStatus? status,
    PayPeriodFrequency? frequency,
  }) async {
    return _repository.getPayPeriods(
      page: page,
      limit: limit,
      status: status,
      frequency: frequency,
    );
  }

  Future<void> loadPayPeriods({
    int page = 1,
    int limit = 100,
    PayPeriodStatus? status,
    PayPeriodFrequency? frequency,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPayPeriods(
      page: page,
      limit: limit,
      status: status,
      frequency: frequency,
    ));
  }

  Future<PayPeriod?> createPayPeriod({
    required String name,
    required String startDate,
    required String endDate,
    String? payDate,
    required PayPeriodFrequency frequency,
    Map<String, dynamic>? notes,
  }) async {
    state = const AsyncValue.loading();
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
      state = AsyncValue.data([newPayPeriod, ...?state.value]);
      return newPayPeriod;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
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
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.map((pp) {
          return pp.id == id ? updatedPayPeriod : pp;
        }).toList());
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> deletePayPeriod(String id) async {
    try {
      await _repository.deletePayPeriod(id);
      
      // Remove from the list
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((pp) => pp.id != id).toList());
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> activatePayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.activatePayPeriod(id);
      if (state.hasValue) {
         state = AsyncValue.data(state.value!.map((pp) {
           return pp.id == id ? updatedPayPeriod : pp;
         }).toList());
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> processPayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.processPayPeriod(id);
      if (state.hasValue) {
         state = AsyncValue.data(state.value!.map((pp) {
           return pp.id == id ? updatedPayPeriod : pp;
         }).toList());
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> completePayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.completePayPeriod(id);
      if (state.hasValue) {
         state = AsyncValue.data(state.value!.map((pp) {
           return pp.id == id ? updatedPayPeriod : pp;
         }).toList());
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> closePayPeriod(String id) async {
    try {
      final updatedPayPeriod = await _repository.closePayPeriod(id);
      if (state.hasValue) {
         state = AsyncValue.data(state.value!.map((pp) {
           return pp.id == id ? updatedPayPeriod : pp;
         }).toList());
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<List<PayPeriod>> generatePayPeriods({
    required PayPeriodFrequency frequency,
    required String startDate,
    required String endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newPeriods = await _repository.generatePayPeriods(
        userId: '', // Backend gets userId from JWT
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Add new periods to state
      final existingPeriods = state.value ?? [];
      state = AsyncValue.data([...newPeriods, ...existingPeriods]);
      return newPeriods;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

// Helper provider for filtered pay periods
final filteredPayPeriodsProvider = Provider<AsyncValue<List<PayPeriod>>>((ref) {
  final payPeriodsState = ref.watch(payPeriodsProvider);
  return payPeriodsState;
});

// Single pay period provider
final payPeriodProvider = Provider.family<AsyncValue<PayPeriod>, String>((ref, id) {
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
