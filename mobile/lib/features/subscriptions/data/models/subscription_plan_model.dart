class SubscriptionPlanModel {
  final String id;
  final String name;
  final String tier;
  final String description;
  final double priceUsd;
  final double priceKes;
  final String currency;
  final bool active;
  final Map<String, bool> features;
  final int sortOrder;
  final String? billingPeriod;
  final int? workerLimit;
  final String? createdAt;
  final String? updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.priceUsd,
    required this.priceKes,
    required this.currency,
    required this.active,
    required this.features,
    required this.sortOrder,
    this.billingPeriod,
    this.workerLimit,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'],
      name: json['name'],
      tier: json['tier'],
      description: json['description'],
      priceUsd: double.parse(json['price_usd'].toString()),
      priceKes: double.parse(json['price_kes'].toString()),
      currency: json['currency'] ?? 'USD',
      active: json['active'] ?? true,
      features: Map<String, bool>.from(json['features'] ?? {}),
      sortOrder: json['sort_order'] ?? 0,
      billingPeriod: json['billing_period'],
      workerLimit: json['worker_limit'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'description': description,
      'price_usd': priceUsd,
      'price_kes': priceKes,
      'currency': currency,
      'active': active,
      'features': features,
      'sort_order': sortOrder,
      'billing_period': billingPeriod,
      'worker_limit': workerLimit,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class UserSubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final String status;
  final String startDate;
  final String? endDate;
  final String? trialEndDate;
  final double amountPaid;
  final String paymentMethod;
  final String createdAt;
  final String updatedAt;
  final SubscriptionPlanModel? plan;

  UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    required this.amountPaid,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.plan,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: json['id'],
      userId: json['userId'],
      planId: json['planId'],
      status: json['status'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      trialEndDate: json['trialEndDate'],
      amountPaid: double.parse(json['amountPaid'].toString()),
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      plan: json['plan'] != null ? SubscriptionPlanModel.fromJson(json['plan']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'trialEndDate': trialEndDate,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'plan': plan?.toJson(),
    };
  }

  String get planTier => plan?.tier ?? 'unknown';
}