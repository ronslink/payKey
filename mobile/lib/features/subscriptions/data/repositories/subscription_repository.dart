import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/subscription_model.dart';
import '../models/subscription_payment_record.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository());

class SubscriptionRepository {
  final ApiService _apiService = ApiService();

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _apiService.getSubscriptionPlans();
      
      // Handle different response types more robustly
      if (response.data == null) {
        return [];
      }
      
      List<dynamic> dataList;
      if (response.data is List) {
        dataList = response.data as List;
      } else if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('data')) {
        final data = response.data as Map<String, dynamic>;
        dataList = data['data'] is List ? data['data'] as List : [data['data']];
      } else {
        // Try to convert single object to list
        dataList = [response.data];
      }
      
      return dataList.map((json) {
        try {
          if (json is Map<String, dynamic>) {
            return SubscriptionPlan(
              id: json['id']?.toString() ?? json['tier']?.toString() ?? 'unknown',
              tier: json['tier']?.toString() ?? 'unknown',
              name: json['name']?.toString() ?? 'Unknown Plan',
              description: json['description']?.toString() ?? '',
              priceUSD: double.tryParse(json['price_usd']?.toString() ?? '0') ?? 0.0,
              priceKES: double.tryParse(json['price_kes']?.toString() ?? '0') ?? 0.0,
              workerLimit: json['worker_limit'] ?? 0,
              features: _extractFeaturesFromJson(json['features']),
              isPopular: _isPopularPlan(json['tier']?.toString()),
              isActive: json['active'] ?? true,
            );
          } else if (json is Map) {
            // Handle other map types
            final mapJson = json as Map<String, dynamic>;
            return SubscriptionPlan(
              id: mapJson['id']?.toString() ?? mapJson['tier']?.toString() ?? 'unknown',
              tier: mapJson['tier']?.toString() ?? 'unknown',
              name: mapJson['name']?.toString() ?? 'Unknown Plan',
              description: mapJson['description']?.toString() ?? '',
              priceUSD: double.tryParse(mapJson['price_usd']?.toString() ?? '0') ?? 0.0,
              priceKES: double.tryParse(mapJson['price_kes']?.toString() ?? '0') ?? 0.0,
              workerLimit: mapJson['worker_limit'] ?? 0,
              features: _extractFeaturesFromJson(mapJson['features']),
              isPopular: _isPopularPlan(mapJson['tier']?.toString()),
              isActive: mapJson['active'] ?? true,
            );
          } else {
            // Fallback for unexpected types
            return SubscriptionPlan(
              id: 'unknown',
              tier: 'unknown',
              name: 'Unknown Plan',
              description: '',
              priceUSD: 0.0,
              priceKES: 0.0,
              workerLimit: 0,
              features: [],
              isPopular: false,
              isActive: true,
            );
          }
        } catch (e) {
          return SubscriptionPlan(
            id: 'unknown',
            tier: 'unknown',
            name: 'Error Parsing Plan',
            description: '',
            priceUSD: 0.0,
            priceKES: 0.0,
            workerLimit: 0,
            features: [],
            isPopular: false,
            isActive: true,
          );
        }
      }).toList();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<Subscription?> getUserSubscription() async {
    try {
      final response = await _apiService.getUserSubscription();
      if (response.data == null) return null;
      
      if (response.data is Map<String, dynamic>) {
        final json = response.data as Map<String, dynamic>;
        
        // Convert API response to Subscription format - Backend structure is simpler than expected
        return Subscription(
          id: json['id']?.toString() ?? 'unknown',
          userId: json['userId']?.toString() ?? '',
          // Backend doesn't have separate planId - use tier as planId
          planId: json['tier']?.toString() ?? 'unknown',
          // Create a simple SubscriptionPlan from tier and planName
          plan: SubscriptionPlan(
            id: json['tier']?.toString() ?? 'unknown',
            tier: json['tier']?.toString() ?? 'unknown',
            name: json['planName']?.toString() ?? json['tier']?.toString() ?? 'Unknown Plan',
            description: '${json['tier']?.toString() ?? 'Unknown'} subscription plan',
            priceUSD: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
            priceKES: 0.0, // Backend doesn't provide KES price
            workerLimit: _getWorkerLimitForTier(json['tier']?.toString()),
            features: _getFeaturesForTier(json['tier']?.toString()),
            isPopular: json['tier']?.toString() == 'BASIC',
            isActive: json['status']?.toString() == 'ACTIVE',
          ),
          status: json['status']?.toString() ?? 'inactive',
          startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
          endDate: json['endDate'] != null && json['endDate'].toString() != 'null'
              ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
              : DateTime.now(),
          amountPaid: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
          currency: json['currency']?.toString() ?? 'USD',
          autoRenew: json['nextBillingDate'] != null, // If there's a next billing date, it's auto-renewing
          cancelledAt: json['status']?.toString() == 'CANCELLED' ? DateTime.tryParse(json['updatedAt']?.toString() ?? '') : null,
          cancellationReason: null,
          metadata: {
            'notes': json['notes']?.toString(),
            'stripeSubscriptionId': json['stripeSubscriptionId']?.toString(),
            'stripePriceId': json['stripePriceId']?.toString(),
          },
          createdAt: json['createdAt']?.toString() != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
          updatedAt: json['updatedAt']?.toString() != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
        );
      }
      
      return null;
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch user subscription: $e');
    }
  }

  // Helper methods to map backend tier to plan features
  int _getWorkerLimitForTier(String? tier) {
    switch (tier?.toUpperCase()) {
      case 'FREE':
        return 1;
      case 'BASIC':
        return 10;
      case 'GOLD':
        return 50;
      case 'PLATINUM':
        return 999;
      default:
        return 1;
    }
  }

  List<String> _getFeaturesForTier(String? tier) {
    switch (tier?.toUpperCase()) {
      case 'FREE':
        return ['Up to 1 worker', 'Basic payroll'];
      case 'BASIC':
        return ['Up to 10 workers', 'Basic payroll', 'Time tracking', 'Tax management'];
      case 'GOLD':
        return ['Up to 50 workers', 'Advanced payroll', 'Time tracking', 'Tax management', 'Multiple properties'];
      case 'PLATINUM':
        return ['Unlimited workers', 'Premium payroll', 'Time tracking', 'Tax management', 'Multiple properties', 'Priority support'];
      default:
        return ['Basic features'];
    }
  }

  List<String> _extractFeaturesFromJson(dynamic featuresJson) {
    if (featuresJson is Map<String, dynamic>) {
      final features = <String>[];
      featuresJson.forEach((key, value) {
        if (value == true) {
          switch (key) {
            case 'up_to_1_worker':
              features.add('Up to 1 worker');
              break;
            case 'up_to_10_workers':
              features.add('Up to 10 workers');
              break;
            case 'up_to_50_workers':
              features.add('Up to 50 workers');
              break;
            case 'unlimited_workers':
              features.add('Unlimited workers');
              break;
            case 'automatic_tax_calculations':
              features.add('Automatic tax calculations');
              break;
            case 'payroll_reports':
              features.add('Payroll reports');
              break;
            case 'time_tracking':
              features.add('Time tracking');
              break;
            case 'multiple_properties':
              features.add('Multiple properties');
              break;
            case 'priority_support':
              features.add('Priority support');
              break;
            default:
              features.add(key.replaceAll('_', ' ').replaceAll('up to', 'Up to'));
          }
        }
      });
      return features;
    } else if (featuresJson is List) {
      return featuresJson.cast<String>();
    }
    return [];
  }

  bool _isPopularPlan(String? tier) {
    return tier?.toUpperCase() == 'BASIC';
  }

  Future<List<SubscriptionPayment>> getSubscriptionPayments() async {
    try {
      // Try to get subscription payment history
      final response = await _apiService.getSubscriptionPaymentHistory();
      
      // Handle different response types more robustly
      if (response.data == null) {
        return [];
      }
      
      List<dynamic> dataList;
      if (response.data is List) {
        dataList = response.data as List;
      } else if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('data')) {
        final data = response.data as Map<String, dynamic>;
        dataList = data['data'] is List ? data['data'] as List : [data['data']];
      } else {
        // Try to convert single object to list
        dataList = [response.data];
      }
      
      return dataList.map((json) {
        try {
          if (json is Map<String, dynamic>) {
            return SubscriptionPayment(
              id: json['id']?.toString() ?? 'unknown',
              subscriptionId: json['subscriptionId']?.toString() ?? '',
              userId: json['userId']?.toString() ?? '',
              amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
              currency: json['currency']?.toString() ?? 'USD',
              status: json['status']?.toString() ?? 'pending',
              paymentMethod: json['paymentMethod']?.toString() ?? 'card',
              provider: json['paymentProvider']?.toString() ?? 'stripe',
              providerTransactionId: json['transactionId']?.toString() ?? '',
              processedAt: json['paidDate']?.toString() != null ? DateTime.tryParse(json['paidDate'].toString()) : null,
              failureReason: json['status']?.toString() == 'FAILED' ? 'Payment failed' : null,
              metadata: json['metadata'],
              createdAt: json['createdAt']?.toString() != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
              updatedAt: json['updatedAt']?.toString() != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
            );
          } else if (json is Map) {
            // Handle other map types
            final mapJson = json as Map<String, dynamic>;
            return SubscriptionPayment(
              id: mapJson['id']?.toString() ?? 'unknown',
              subscriptionId: mapJson['subscriptionId']?.toString() ?? '',
              userId: mapJson['userId']?.toString() ?? '',
              amount: double.tryParse(mapJson['amount']?.toString() ?? '0') ?? 0.0,
              currency: mapJson['currency']?.toString() ?? 'USD',
              status: mapJson['status']?.toString() ?? 'pending',
              paymentMethod: mapJson['paymentMethod']?.toString() ?? 'card',
              provider: mapJson['paymentProvider']?.toString() ?? 'stripe',
              providerTransactionId: mapJson['transactionId']?.toString() ?? '',
              processedAt: mapJson['paidDate']?.toString() != null ? DateTime.tryParse(mapJson['paidDate'].toString()) : null,
              failureReason: mapJson['status']?.toString() == 'FAILED' ? 'Payment failed' : null,
              metadata: mapJson['metadata'],
              createdAt: mapJson['createdAt']?.toString() != null ? DateTime.tryParse(mapJson['createdAt'].toString()) : null,
              updatedAt: mapJson['updatedAt']?.toString() != null ? DateTime.tryParse(mapJson['updatedAt'].toString()) : null,
            );
          } else {
            // Fallback for unexpected types
            return SubscriptionPayment(
              id: 'unknown',
              subscriptionId: '',
              userId: '',
              amount: 0.0,
              currency: 'USD',
              status: 'pending',
              paymentMethod: 'card',
              provider: 'stripe',
              providerTransactionId: '',
              processedAt: null,
              failureReason: null,
              metadata: null,
              createdAt: null,
              updatedAt: null,
            );
          }
        } catch (e) {
          return SubscriptionPayment(
            id: 'unknown',
            subscriptionId: '',
            userId: '',
            amount: 0.0,
            currency: 'USD',
            status: 'pending',
            paymentMethod: 'card',
            provider: 'stripe',
            providerTransactionId: '',
            processedAt: null,
            failureReason: null,
            metadata: null,
            createdAt: null,
            updatedAt: null,
          );
        }
      }).toList();
    } on DioException catch (e) {
      // Handle 404 errors gracefully (endpoint might not exist)
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      // If endpoint doesn't exist or other errors, return empty list
      return [];
    }
  }

  // Payment history specifically for subscription payments (not payroll)
  Future<List<SubscriptionPaymentRecord>> getSubscriptionPaymentHistory({
    int page = 1,
    int limit = 50,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final payments = await getSubscriptionPayments();
    return payments.map((payment) => SubscriptionPaymentRecord(
      id: payment.id,
      subscriptionId: payment.subscriptionId,
      userId: payment.userId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      paymentMethod: payment.paymentMethod,
      provider: payment.provider,
      providerTransactionId: payment.providerTransactionId,
      processedAt: payment.processedAt ?? DateTime.now(),
      failureReason: payment.failureReason,
      metadata: payment.metadata,
      createdAt: payment.createdAt ?? DateTime.now(),
      updatedAt: payment.updatedAt ?? DateTime.now(),
    )).toList();
  }
  Future<String> subscribeWithStripe(String planId) async {
    try {
      final response = await _apiService.subscriptions.subscribeWithStripe(planId);
      final data = response.data;
      if (data is Map && data.containsKey('checkoutUrl')) {
        return data['checkoutUrl'].toString();
      }
      throw Exception('Invalid response from server');
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to initiate subscription: $e');
    }
  }

  /// Initiate M-Pesa STK Push for subscription payment
  Future<MpesaSubscriptionResult> subscribeWithMpesa(String planId, String phoneNumber) async {
    try {
      final response = await _apiService.dio.post(
        '/subscriptions/mpesa-subscribe',
        data: {
          'planId': planId,
          'phoneNumber': phoneNumber,
        },
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MpesaSubscriptionResult(
          success: data['success'] ?? false,
          message: data['message']?.toString() ?? 'Unknown response',
          paymentId: data['paymentId']?.toString(),
          checkoutRequestId: data['checkoutRequestId']?.toString(),
          subscriptionId: data['subscriptionId']?.toString(),
        );
      }
      throw Exception('Invalid response from server');
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to initiate M-Pesa subscription: $e');
    }
  }

  /// Check M-Pesa payment status
  Future<MpesaPaymentStatus> checkMpesaPaymentStatus(String paymentId) async {
    try {
      final response = await _apiService.dio.get(
        '/subscriptions/mpesa-payment-status/$paymentId',
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MpesaPaymentStatus(
          paymentId: data['paymentId']?.toString() ?? '',
          status: data['status']?.toString() ?? 'PENDING',
          amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
          currency: data['currency']?.toString() ?? 'KES',
          paidDate: data['paidDate'] != null ? DateTime.tryParse(data['paidDate'].toString()) : null,
        );
      }
      throw Exception('Invalid response from server');
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }
}

/// Result of initiating M-Pesa subscription
class MpesaSubscriptionResult {
  final bool success;
  final String message;
  final String? paymentId;
  final String? checkoutRequestId;
  final String? subscriptionId;

  MpesaSubscriptionResult({
    required this.success,
    required this.message,
    this.paymentId,
    this.checkoutRequestId,
    this.subscriptionId,
  });
}

/// Status of M-Pesa payment
class MpesaPaymentStatus {
  final String paymentId;
  final String status;
  final double amount;
  final String currency;
  final DateTime? paidDate;

  MpesaPaymentStatus({
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidDate,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}