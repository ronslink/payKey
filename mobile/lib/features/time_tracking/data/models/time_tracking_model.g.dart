// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_tracking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimeEntryImpl _$$TimeEntryImplFromJson(Map<String, dynamic> json) =>
    _$TimeEntryImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      workerId: json['workerId'] as String,
      clockInTime: json['clockInTime'] as String,
      clockOutTime: json['clockOutTime'] as String?,
      clockInLatitude: (json['clockInLatitude'] as num?)?.toDouble(),
      clockInLongitude: (json['clockInLongitude'] as num?)?.toDouble(),
      clockOutLatitude: (json['clockOutLatitude'] as num?)?.toDouble(),
      clockOutLongitude: (json['clockOutLongitude'] as num?)?.toDouble(),
      totalHours: (json['totalHours'] as num?)?.toDouble(),
      status: $enumDecode(_$TimeEntryStatusEnumMap, json['status']),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String,
      propertyId: json['propertyId'] as String?,
    );

Map<String, dynamic> _$$TimeEntryImplToJson(_$TimeEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'workerId': instance.workerId,
      'clockInTime': instance.clockInTime,
      'clockOutTime': instance.clockOutTime,
      'clockInLatitude': instance.clockInLatitude,
      'clockInLongitude': instance.clockInLongitude,
      'clockOutLatitude': instance.clockOutLatitude,
      'clockOutLongitude': instance.clockOutLongitude,
      'totalHours': instance.totalHours,
      'status': _$TimeEntryStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
      'propertyId': instance.propertyId,
    };

const _$TimeEntryStatusEnumMap = {
  TimeEntryStatus.inProgress: 'IN_PROGRESS',
  TimeEntryStatus.completed: 'COMPLETED',
};

_$ClockInRequestImpl _$$ClockInRequestImplFromJson(Map<String, dynamic> json) =>
    _$ClockInRequestImpl(
      workerId: json['workerId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$ClockInRequestImplToJson(
  _$ClockInRequestImpl instance,
) => <String, dynamic>{
  'workerId': instance.workerId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'notes': instance.notes,
};

_$ClockOutRequestImpl _$$ClockOutRequestImplFromJson(
  Map<String, dynamic> json,
) => _$ClockOutRequestImpl(
  timeEntryId: json['timeEntryId'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$ClockOutRequestImplToJson(
  _$ClockOutRequestImpl instance,
) => <String, dynamic>{
  'timeEntryId': instance.timeEntryId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'notes': instance.notes,
};
