// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    _SubscriptionPlan(
      id: json['id'] as String,
      tier: json['tier'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priceUSD: (json['priceUSD'] as num).toDouble(),
      priceKES: (json['priceKES'] as num).toDouble(),
      workerLimit: (json['workerLimit'] as num).toInt(),
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPopular: json['isPopular'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubscriptionPlanToJson(_SubscriptionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tier': instance.tier,
      'name': instance.name,
      'description': instance.description,
      'priceUSD': instance.priceUSD,
      'priceKES': instance.priceKES,
      'workerLimit': instance.workerLimit,
      'features': instance.features,
      'isPopular': instance.isPopular,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String,
      autoRenew: json['autoRenew'] as bool? ?? false,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'planId': instance.planId,
      'plan': instance.plan,
      'status': instance.status,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'amountPaid': instance.amountPaid,
      'currency': instance.currency,
      'autoRenew': instance.autoRenew,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_SubscriptionPayment _$SubscriptionPaymentFromJson(Map<String, dynamic> json) =>
    _SubscriptionPayment(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      provider: json['provider'] as String,
      providerTransactionId: json['providerTransactionId'] as String,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubscriptionPaymentToJson(
  _SubscriptionPayment instance,
) => <String, dynamic>{
  'id': instance.id,
  'subscriptionId': instance.subscriptionId,
  'userId': instance.userId,
  'amount': instance.amount,
  'currency': instance.currency,
  'status': instance.status,
  'paymentMethod': instance.paymentMethod,
  'provider': instance.provider,
  'providerTransactionId': instance.providerTransactionId,
  'processedAt': instance.processedAt?.toIso8601String(),
  'failureReason': instance.failureReason,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_SubscriptionUsage _$SubscriptionUsageFromJson(Map<String, dynamic> json) =>
    _SubscriptionUsage(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      userId: json['userId'] as String,
      currentWorkers: (json['currentWorkers'] as num).toInt(),
      maxWorkers: (json['maxWorkers'] as num).toInt(),
      usagePercentage: (json['usagePercentage'] as num).toDouble(),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      breakdown: json['breakdown'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SubscriptionUsageToJson(_SubscriptionUsage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subscriptionId': instance.subscriptionId,
      'userId': instance.userId,
      'currentWorkers': instance.currentWorkers,
      'maxWorkers': instance.maxWorkers,
      'usagePercentage': instance.usagePercentage,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
      'breakdown': instance.breakdown,
    };
