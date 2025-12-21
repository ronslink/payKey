import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/models/subscription_payment_record.dart';

class SubscriptionPaymentHistoryNotifier extends AsyncNotifier<List<SubscriptionPaymentRecord>> {
  late final SubscriptionRepository _repository;

  @override
  FutureOr<List<SubscriptionPaymentRecord>> build() {
    _repository = ref.watch(subscriptionRepositoryProvider);
    return []; // Initial empty state or loading? Let's default to empty array, data loaded via method call usually
  }

  Future<void> loadPaymentHistory({
    int page = 1,
    int limit = 50,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
         return await _repository.getSubscriptionPaymentHistory(
          page: page,
          limit: limit,
          status: status,
          startDate: startDate,
          endDate: endDate,
        );
      });
  }

  Future<void> loadUserSubscriptionPaymentHistory() async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _repository.getSubscriptionPaymentHistory());
  }
}

// Provider for subscription payment history (NOT payroll)
final subscriptionPaymentHistoryProvider =
    AsyncNotifierProvider<SubscriptionPaymentHistoryNotifier, List<SubscriptionPaymentRecord>>(SubscriptionPaymentHistoryNotifier.new);

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