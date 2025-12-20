// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CountryModelImpl _$$CountryModelImplFromJson(Map<String, dynamic> json) =>
    _$CountryModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      currency: json['currency'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$CountryModelImplToJson(_$CountryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'currency': instance.currency,
      'isActive': instance.isActive,
    };
