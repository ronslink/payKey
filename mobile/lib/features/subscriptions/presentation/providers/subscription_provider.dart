import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/models/subscription_model.dart';

// Provider for subscription plans
final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlan>>((ref) async {
  final repository = ref.read(subscriptionRepositoryProvider);
  return repository.getSubscriptionPlans();
});

// Provider for user subscription
final userSubscriptionProvider =
    FutureProvider<Subscription?>((ref) async {
  final repository = ref.read(subscriptionRepositoryProvider);
  return repository.getUserSubscription();
});

// Combined subscription data provider
final subscriptionDataProvider = Provider<AsyncValue<({
  List<SubscriptionPlan>? plans,
  Subscription? userSubscription,
})>>((ref) {
  final plansState = ref.watch(subscriptionPlansProvider);
  final userSubState = ref.watch(userSubscriptionProvider);
  
  return AsyncValue.data((
    plans: plansState.value,
    userSubscription: userSubState.value,
  ));
});

// Helper provider to check if user has an active subscription
final hasActiveSubscriptionProvider = Provider<bool>((ref) {
  final userSubState = ref.watch(userSubscriptionProvider);
  return userSubState.value?.status == 'active';
});

// Provider for subscription payment history
final subscriptionPaymentHistoryProvider =
    FutureProvider<List<SubscriptionPayment>>((ref) async {
  final repository = ref.read(subscriptionRepositoryProvider);
  return repository.getSubscriptionPayments();
});