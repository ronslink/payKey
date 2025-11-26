import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/models/subscription_payment_record.dart';

class SubscriptionPaymentHistoryNotifier extends StateNotifier<AsyncValue<List<SubscriptionPaymentRecord>>> {
  final SubscriptionRepository _repository;

  SubscriptionPaymentHistoryNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadPaymentHistory({
    int page = 1,
    int limit = 50,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      state = const AsyncValue.loading();
      final result = await _repository.getSubscriptionPaymentHistory(
        page: page,
        limit: limit,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadUserSubscriptionPaymentHistory() async {
    try {
      state = const AsyncValue.loading();
      final payments = await _repository.getSubscriptionPaymentHistory();
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Provider for subscription payment history (NOT payroll)
final subscriptionPaymentHistoryProvider =
    StateNotifierProvider<SubscriptionPaymentHistoryNotifier, AsyncValue<List<SubscriptionPaymentRecord>>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionPaymentHistoryNotifier(repository);
});

// Helper provider to reload payment history
final subscriptionPaymentHistoryLoaderProvider =
    Provider((ref) => () async {
      await ref.read(subscriptionPaymentHistoryProvider.notifier).loadPaymentHistory();
    });

// Helper provider to load user subscription payment history  
final userSubscriptionPaymentHistoryProvider =
    Provider((ref) => () async {
      await ref.read(subscriptionPaymentHistoryProvider.notifier).loadUserSubscriptionPaymentHistory();
    });