import 'package:dio/dio.dart';
import '../api_service.dart';

extension SubscriptionService on ApiService {
  Future<Response> getSubscriptionPlans() async {
    return dio.get(
      '/subscriptions/plans',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> subscribeToPlan(String planId) async {
    return dio.post('/subscriptions/subscribe', data: {
      'planId': planId,
    });
  }

  Future<Response> getUserSubscription() async {
    return dio.get(
      '/subscriptions/current',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> getSubscriptionPaymentHistory({
    int? page,
    int? limit,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    
    return dio.get(
      '/subscriptions/subscription-payment-history',
      queryParameters: queryParams,
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> getSubscriptionUsage() async {
    return dio.get(
      '/subscriptions/usage',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      )
    );
  }

  Future<Response> cancelSubscription(String subscriptionId) async {
    return dio.post('/subscriptions/$subscriptionId/cancel');
  }

  Future<Response> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    return dio.patch('/subscriptions/$subscriptionId', data: updates);
  }

  Future<Response> resumeSubscription(String subscriptionId) async {
    return dio.post('/subscriptions/$subscriptionId/resume');
  }

  Future<Response> upgradeSubscription(String subscriptionId, String newPlanId) async {
    return dio.post('/subscriptions/$subscriptionId/upgrade', data: {
      'newPlanId': newPlanId,
    });
  }
}
