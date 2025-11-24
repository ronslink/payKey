import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pay_period_model.dart';
import '../repositories/pay_period_repository.dart';

class PayPeriodsController extends StateNotifier<AsyncValue<List<PayPeriod>>> {
  final PayPeriodRepository _repository;

  PayPeriodsController(this._repository) : super(const AsyncValue.loading()) {
    loadPayPeriods();
  }

  Future<void> loadPayPeriods() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getPayPeriods());
  }

  Future<void> createPayPeriod(int year, int month) async {
    // state = const AsyncValue.loading(); // Optional: show loading state
    await _repository.createPayPeriod(year, month);
    await loadPayPeriods();
  }
}

final payPeriodsProvider = StateNotifierProvider<PayPeriodsController, AsyncValue<List<PayPeriod>>>((ref) {
  return PayPeriodsController(ref.read(payPeriodRepositoryProvider));
});

final currentPayPeriodProvider = StateProvider<PayPeriod?>((ref) => null);
