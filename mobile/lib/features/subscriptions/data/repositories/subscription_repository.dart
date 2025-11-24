import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/subscription_plan_model.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository());

class SubscriptionRepository {
  final ApiService _apiService = ApiService();

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final response = await _apiService.getSubscriptionPlans();
      final data = response.data as List;
      
      // Convert each item to a proper Map<String, dynamic>
      final plans = data.map((json) {
        if (json is Map) {
          return SubscriptionPlanModel.fromJson(json as Map<String, dynamic>);
        } else {
          // Handle case where json might be a JsonMap or other type
          return SubscriptionPlanModel.fromJson({
            'id': json['tier']?.toString() ?? 'unknown',
            'name': json['name']?.toString() ?? 'Unknown Plan',
            'tier': json['tier']?.toString() ?? 'unknown',
            'description': json['description']?.toString() ?? '',
            'price_usd': double.tryParse(json['price_usd']?.toString() ?? '0') ?? 0.0,
            'price_kes': double.tryParse(json['price_kes']?.toString() ?? '0') ?? 0.0,
            'currency': json['currency']?.toString() ?? 'USD',
            'active': json['active'] ?? true,
            'features': json['features'] ?? {},
            'sort_order': json['sort_order'] ?? 0,
            'worker_limit': json['worker_limit'] ?? 0,
            'created_at': json['created_at']?.toString(),
            'updated_at': json['updated_at']?.toString(),
          });
        }
      }).toList();
      
      return plans;
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<UserSubscriptionModel?> getUserSubscription() async {
    try {
      final response = await _apiService.getUserSubscription();
      if (response.data == null) return null;
      
      // Handle different response formats
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UserSubscriptionModel.fromJson(data);
      } else {
        // Return null for non-map responses (like free tier responses)
        return null;
      }
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch user subscription: $e');
    }
  }

  Future<void> subscribeToPlan(String planId) async {
    try {
      await _apiService.subscribeToPlan(planId);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to subscribe to plan: $e');
    }
  }
}