// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pay_period_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PayPeriodImpl _$$PayPeriodImplFromJson(Map<String, dynamic> json) =>
    _$PayPeriodImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status:
          $enumDecodeNullable(_$PayPeriodStatusEnumMap, json['status']) ??
          PayPeriodStatus.open,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PayPeriodImplToJson(_$PayPeriodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': _$PayPeriodStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PayPeriodStatusEnumMap = {
  PayPeriodStatus.open: 'OPEN',
  PayPeriodStatus.processing: 'PROCESSING',
  PayPeriodStatus.closed: 'CLOSED',
};
