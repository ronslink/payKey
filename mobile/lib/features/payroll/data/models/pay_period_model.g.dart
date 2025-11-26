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
      totalWorkers: (json['totalWorkers'] as num).toInt(),
      totalGrossAmount: (json['totalGrossAmount'] as num).toDouble(),
      totalNetAmount: (json['totalNetAmount'] as num).toDouble(),
      processedWorkers: (json['processedWorkers'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
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
      'processedWorkers': instance.processedWorkers,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'notes': instance.notes,
    };

const _$PayPeriodFrequencyEnumMap = {
  PayPeriodFrequency.weekly: 'weekly',
  PayPeriodFrequency.biWeekly: 'biWeekly',
  PayPeriodFrequency.monthly: 'monthly',
  PayPeriodFrequency.quarterly: 'quarterly',
  PayPeriodFrequency.yearly: 'yearly',
};

const _$PayPeriodStatusEnumMap = {
  PayPeriodStatus.DRAFT: 'DRAFT',
  PayPeriodStatus.ACTIVE: 'ACTIVE',
  PayPeriodStatus.PROCESSING: 'PROCESSING',
  PayPeriodStatus.COMPLETED: 'COMPLETED',
  PayPeriodStatus.CLOSED: 'CLOSED',
  PayPeriodStatus.CANCELLED: 'CANCELLED',
};

_$CreatePayPeriodRequestImpl _$$CreatePayPeriodRequestImplFromJson(
  Map<String, dynamic> json,
) => _$CreatePayPeriodRequestImpl(
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  frequency: $enumDecode(_$PayPeriodFrequencyEnumMap, json['frequency']),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$CreatePayPeriodRequestImplToJson(
  _$CreatePayPeriodRequestImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'frequency': _$PayPeriodFrequencyEnumMap[instance.frequency]!,
  'notes': instance.notes,
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
