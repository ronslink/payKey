// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pay_period_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PayPeriodImpl _$$PayPeriodImplFromJson(Map<String, dynamic> json) =>
    _$PayPeriodImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      frequency: $enumDecode(_$PayPeriodFrequencyEnumMap, json['frequency']),
      status: $enumDecode(_$PayPeriodStatusEnumMap, json['status']),
      totalWorkers: _intFromJson(json['totalWorkers']),
      totalGrossAmount: _doubleFromJson(json['totalGrossAmount']),
      totalNetAmount: _doubleFromJson(json['totalNetAmount']),
      totalTaxAmount: _doubleFromJson(json['totalTaxAmount']),
      processedWorkers: _intFromJson(json['processedWorkers']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      userId: json['userId'] as String?,
      payDate: json['payDate'] == null
          ? null
          : DateTime.parse(json['payDate'] as String),
    );

Map<String, dynamic> _$$PayPeriodImplToJson(_$PayPeriodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'frequency': _$PayPeriodFrequencyEnumMap[instance.frequency]!,
      'status': _$PayPeriodStatusEnumMap[instance.status]!,
      'totalWorkers': instance.totalWorkers,
      'totalGrossAmount': instance.totalGrossAmount,
      'totalNetAmount': instance.totalNetAmount,
      'totalTaxAmount': instance.totalTaxAmount,
      'processedWorkers': instance.processedWorkers,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'notes': instance.notes,
      'userId': instance.userId,
      'payDate': instance.payDate?.toIso8601String(),
    };

const _$PayPeriodFrequencyEnumMap = {
  PayPeriodFrequency.weekly: 'WEEKLY',
  PayPeriodFrequency.biWeekly: 'BIWEEKLY',
  PayPeriodFrequency.monthly: 'MONTHLY',
  PayPeriodFrequency.quarterly: 'QUARTERLY',
  PayPeriodFrequency.yearly: 'YEARLY',
};

const _$PayPeriodStatusEnumMap = {
  PayPeriodStatus.draft: 'DRAFT',
  PayPeriodStatus.active: 'ACTIVE',
  PayPeriodStatus.processing: 'PROCESSING',
  PayPeriodStatus.completed: 'COMPLETED',
  PayPeriodStatus.closed: 'CLOSED',
  PayPeriodStatus.cancelled: 'CANCELLED',
};

_$CreatePayPeriodRequestImpl _$$CreatePayPeriodRequestImplFromJson(
  Map<String, dynamic> json,
) => _$CreatePayPeriodRequestImpl(
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  frequency: $enumDecode(_$PayPeriodFrequencyEnumMap, json['frequency']),
  notes: json['notes'] as String?,
  isOffCycle: json['isOffCycle'] as bool? ?? false,
);

Map<String, dynamic> _$$CreatePayPeriodRequestImplToJson(
  _$CreatePayPeriodRequestImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'frequency': _$PayPeriodFrequencyEnumMap[instance.frequency]!,
  'notes': instance.notes,
  'isOffCycle': instance.isOffCycle,
};

_$UpdatePayPeriodRequestImpl _$$UpdatePayPeriodRequestImplFromJson(
  Map<String, dynamic> json,
) => _$UpdatePayPeriodRequestImpl(
  name: json['name'] as String?,
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  frequency: $enumDecodeNullable(
    _$PayPeriodFrequencyEnumMap,
    json['frequency'],
  ),
  status: $enumDecodeNullable(_$PayPeriodStatusEnumMap, json['status']),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$UpdatePayPeriodRequestImplToJson(
  _$UpdatePayPeriodRequestImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'startDate': instance.startDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'frequency': _$PayPeriodFrequencyEnumMap[instance.frequency],
  'status': _$PayPeriodStatusEnumMap[instance.status],
  'notes': instance.notes,
};
