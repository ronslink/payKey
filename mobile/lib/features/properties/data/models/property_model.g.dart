// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PropertyImpl _$$PropertyImplFromJson(Map<String, dynamic> json) =>
    _$PropertyImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geofenceRadius: (json['geofenceRadius'] as num?)?.toInt() ?? 100,
      isActive: json['isActive'] as bool? ?? true,
      workerCount: (json['workerCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$PropertyImplToJson(_$PropertyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'geofenceRadius': instance.geofenceRadius,
      'isActive': instance.isActive,
      'workerCount': instance.workerCount,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_$PropertySummaryImpl _$$PropertySummaryImplFromJson(
  Map<String, dynamic> json,
) => _$PropertySummaryImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  workerCount: (json['workerCount'] as num).toInt(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$$PropertySummaryImplToJson(
  _$PropertySummaryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'workerCount': instance.workerCount,
  'isActive': instance.isActive,
};

_$CreatePropertyRequestImpl _$$CreatePropertyRequestImplFromJson(
  Map<String, dynamic> json,
) => _$CreatePropertyRequestImpl(
  name: json['name'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  geofenceRadius: (json['geofenceRadius'] as num?)?.toInt() ?? 100,
);

Map<String, dynamic> _$$CreatePropertyRequestImplToJson(
  _$CreatePropertyRequestImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'geofenceRadius': instance.geofenceRadius,
};

_$UpdatePropertyRequestImpl _$$UpdatePropertyRequestImplFromJson(
  Map<String, dynamic> json,
) => _$UpdatePropertyRequestImpl(
  name: json['name'] as String?,
  address: json['address'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  geofenceRadius: (json['geofenceRadius'] as num?)?.toInt(),
  isActive: json['isActive'] as bool?,
);

Map<String, dynamic> _$$UpdatePropertyRequestImplToJson(
  _$UpdatePropertyRequestImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'geofenceRadius': instance.geofenceRadius,
  'isActive': instance.isActive,
};
