// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      workerId: json['workerId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'KES',
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      status: $enumDecode(_$TransactionStatusEnumMap, json['status']),
      providerRef: json['providerRef'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'workerId': instance.workerId,
      'amount': instance.amount,
      'currency': instance.currency,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'providerRef': instance.providerRef,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.subscription: 'SUBSCRIPTION',
  TransactionType.salaryPayout: 'SALARY_PAYOUT',
  TransactionType.topup: 'TOPUP',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'PENDING',
  TransactionStatus.success: 'SUCCESS',
  TransactionStatus.failed: 'FAILED',
};

_$TopupRequestImpl _$$TopupRequestImplFromJson(Map<String, dynamic> json) =>
    _$TopupRequestImpl(
      phoneNumber: json['phoneNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$$TopupRequestImplToJson(_$TopupRequestImpl instance) =>
    <String, dynamic>{
      'phoneNumber': instance.phoneNumber,
      'amount': instance.amount,
    };

_$PaymentResponseImpl _$$PaymentResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PaymentResponseImpl(
  message: json['message'] as String,
  checkoutRequestId: json['checkoutRequestId'] as String?,
  transaction: json['transaction'] == null
      ? null
      : Transaction.fromJson(json['transaction'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$PaymentResponseImplToJson(
  _$PaymentResponseImpl instance,
) => <String, dynamic>{
  'message': instance.message,
  'checkoutRequestId': instance.checkoutRequestId,
  'transaction': instance.transaction,
};
