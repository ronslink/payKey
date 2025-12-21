import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
abstract class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String id,
    required String tier,
    required String name,
    required String description,
    required double priceUSD,
    required double priceKES,
    required int workerLimit,
    required List<String> features,
    @Default(false) bool isPopular,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);
}

@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String userId,
    required String planId,
    required SubscriptionPlan plan,
    required String status,
    required DateTime startDate,
    required DateTime endDate,
    @Default(0.0) double amountPaid,
    required String currency,
    @Default(false) bool autoRenew,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

@freezed
abstract class SubscriptionPayment with _$SubscriptionPayment {
  const factory SubscriptionPayment({
    required String id,
    required String subscriptionId,
    required String userId,
    required double amount,
    required String currency,
    required String status,
    required String paymentMethod,
    required String provider,
    required String providerTransactionId,
    DateTime? processedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SubscriptionPayment;

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPaymentFromJson(json);
}

@freezed
abstract class SubscriptionUsage with _$SubscriptionUsage {
  const factory SubscriptionUsage({
    required String id,
    required String subscriptionId,
    required String userId,
    required int currentWorkers,
    required int maxWorkers,
    required double usagePercentage,
    DateTime? lastUpdated,
    Map<String, dynamic>? breakdown,
  }) = _SubscriptionUsage;

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionUsageFromJson(json);
}
