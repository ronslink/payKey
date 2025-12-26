// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) =>
    _PropertyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: _parseAddress(json['address']),
      userId: json['userId'] as String,
      geofenceRadius: (json['geofenceRadius'] as num?)?.toInt() ?? 100,
      isActive: json['isActive'] as bool? ?? true,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      what3words: json['what3words'] as String?,
      workerCount: (json['workerCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PropertyModelToJson(_PropertyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'userId': instance.userId,
      'geofenceRadius': instance.geofenceRadius,
      'isActive': instance.isActive,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'what3words': instance.what3words,
      'workerCount': instance.workerCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_CreatePropertyRequest _$CreatePropertyRequestFromJson(
  Map<String, dynamic> json,
) => _CreatePropertyRequest(
  name: json['name'] as String,
  address: json['address'] as String,
  geofenceRadius: (json['geofenceRadius'] as num?)?.toInt() ?? 100,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  what3words: json['what3words'] as String?,
);

Map<String, dynamic> _$CreatePropertyRequestToJson(
  _CreatePropertyRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'geofenceRadius': instance.geofenceRadius,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'what3words': instance.what3words,
};

_UpdatePropertyRequest _$UpdatePropertyRequestFromJson(
  Map<String, dynamic> json,
) => _UpdatePropertyRequest(
  name: json['name'] as String?,
  address: json['address'] as String?,
  geofenceRadius: (json['geofenceRadius'] as num?)?.toInt(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  what3words: json['what3words'] as String?,
  isActive: json['isActive'] as bool?,
);

Map<String, dynamic> _$UpdatePropertyRequestToJson(
  _UpdatePropertyRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'address': ?instance.address,
  'geofenceRadius': ?instance.geofenceRadius,
  'latitude': ?instance.latitude,
  'longitude': ?instance.longitude,
  'what3words': ?instance.what3words,
  'isActive': ?instance.isActive,
};
