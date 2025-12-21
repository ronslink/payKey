// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Property _$PropertyFromJson(Map<String, dynamic> json) => _Property(
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

Map<String, dynamic> _$PropertyToJson(_Property instance) => <String, dynamic>{
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

_PropertySummary _$PropertySummaryFromJson(Map<String, dynamic> json) =>
    _PropertySummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      workerCount: (json['workerCount'] as num).toInt(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$PropertySummaryToJson(_PropertySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'workerCount': instance.workerCount,
      'isActive': instance.isActive,
    };

_CreatePropertyRequest _$CreatePropertyRequestFromJson(
  Map<String, dynamic> json,
) => _CreatePropertyRequest(
  name: json['name'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  geofenceRadius: (json['geofenceRadius'] as num?)?.toInt() ?? 100,
);

Map<String, dynamic> _$CreatePropertyRequestToJson(
  _CreatePropertyRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'geofenceRadius': instance.geofenceRadius,
};

_UpdatePropertyRequest _$UpdatePropertyRequestFromJson(
  Map<String, dynamic> json,
) => _UpdatePropertyRequest(
  name: json['name'] as String?,
  address: json['address'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  geofenceRadius: (json['geofenceRadius'] as num?)?.toInt(),
  isActive: json['isActive'] as bool?,
);

Map<String, dynamic> _$UpdatePropertyRequestToJson(
  _UpdatePropertyRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'geofenceRadius': instance.geofenceRadius,
  'isActive': instance.isActive,
};
