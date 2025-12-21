// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CountryModel _$CountryModelFromJson(Map<String, dynamic> json) =>
    _CountryModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$CountryModelToJson(_CountryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'currency': instance.currency,
      'isActive': instance.isActive,
    };
