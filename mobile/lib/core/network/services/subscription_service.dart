import 'package:dio/dio.dart';
import '../api_service.dart';

extension SubscriptionService on ApiService {
  // Stripe-based subscription endpoints
  Future<Response> getSubscriptionPlans() async {
    return dio.get('/payments/subscriptions/plans');
  }

  Future<Response> getCurrentSubscription() async {
    return dio.get('/payments/subscriptions/current');
  }

  Future<Response> createCheckoutSession(String planId) async {
    return dio.post('/payments/subscriptions/checkout', data: {
      'planId': planId,
    });
  }

  Future<Response> cancelSubscription(String subscriptionId) async {
    return dio.put('/payments/subscriptions/$subscriptionId/cancel');
  }

  Future<Response> getSubscriptionPaymentHistory() async {
    return dio.get('/payments/subscriptions/payment-history');
  }

  Future<Response> getSubscriptionUsage() async {
    return dio.get('/payments/subscriptions/usage');
  }

  Future<Response> getStripeAccountStatus() async {
    return dio.get('/payments/subscriptions/stripe-status');
  }

  // Legacy endpoints (for backward compatibility)
  Future<Response> subscribeToPlan(String planId) async {
    // Legacy method - redirects to checkout
    return createCheckoutSession(planId);
  }

  Future<Response> getSubscriptionPaymentHistoryLegacy({
    int? page,
    int? limit,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    // Legacy method with query params - redirects to new endpoint
    return getSubscriptionPaymentHistory();
  }

  Future<Response> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    // Note: This might need to be implemented differently with Stripe
    return dio.patch('/subscriptions/$subscriptionId', data: updates);
  }

  Future<Response> resumeSubscription(String subscriptionId) async {
    return dio.post('/payments/subscriptions/$subscriptionId/resume');
  }

  Future<Response> upgradeSubscription(String subscriptionId, String newPlanId) async {
    return dio.post('/payments/subscriptions/$subscriptionId/upgrade', data: {
      'newPlanId': newPlanId,
    });
  }
}
