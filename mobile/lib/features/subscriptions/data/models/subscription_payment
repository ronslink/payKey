class SubscriptionPaymentRecord {
  final String id;
  final String subscriptionId;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String provider;
  final String providerTransactionId;
  final DateTime? processedAt;
  final String? failureReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPaymentRecord({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.provider,
    required this.providerTransactionId,
    this.processedAt,
    this.failureReason,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPaymentRecord.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentRecord(
      id: json['id'] as String,
      subscriptionId: json['subscriptionId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      provider: json['provider'] as String,
      providerTransactionId: json['providerTransactionId'] as String,
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscriptionId': subscriptionId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'provider': provider,
      'providerTransactionId': providerTransactionId,
      'processedAt': processedAt?.toIso8601String(),
      'failureReason': failureReason,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SubscriptionPaymentRecord copyWith({
    String? id,
    String? subscriptionId,
    String? userId,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? provider,
    String? providerTransactionId,
    DateTime? processedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPaymentRecord(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      provider: provider ?? this.provider,
      providerTransactionId: providerTransactionId ?? this.providerTransactionId,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}