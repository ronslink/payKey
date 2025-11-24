import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository());

final subscriptionPlansProvider = StateNotifierProvider<SubscriptionPlansNotifier, AsyncValue<List<SubscriptionPlanModel>>>((ref) {
  return SubscriptionPlansNotifier(
    ref.read(subscriptionRepositoryProvider),
  );
});

final userSubscriptionProvider = StateNotifierProvider<UserSubscriptionNotifier, AsyncValue<UserSubscriptionModel?>>((ref) {
  return UserSubscriptionNotifier(
    ref.read(subscriptionRepositoryProvider),
  );
});

class SubscriptionPlansNotifier extends StateNotifier<AsyncValue<List<SubscriptionPlanModel>>> {
  final SubscriptionRepository _repository;

  SubscriptionPlansNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repository.getSubscriptionPlans();
      state = AsyncValue.data(plans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class UserSubscriptionNotifier extends StateNotifier<AsyncValue<UserSubscriptionModel?>> {
  final SubscriptionRepository _repository;

  UserSubscriptionNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchUserSubscription();
  }

  Future<void> fetchUserSubscription() async {
    state = const AsyncValue.loading();
    try {
      final subscription = await _repository.getUserSubscription();
      state = AsyncValue.data(subscription);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> subscribeToPlan(String planId) async {
    try {
      await _repository.subscribeToPlan(planId);
      await fetchUserSubscription(); // Refresh the subscription
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}