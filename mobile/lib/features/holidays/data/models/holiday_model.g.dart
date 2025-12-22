// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HolidayModel _$HolidayModelFromJson(Map<String, dynamic> json) =>
    _HolidayModel(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      isRecurring: json['isRecurring'] as bool,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$HolidayModelToJson(_HolidayModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'date': instance.date.toIso8601String(),
      'isRecurring': instance.isRecurring,
      'description': instance.description,
    };
