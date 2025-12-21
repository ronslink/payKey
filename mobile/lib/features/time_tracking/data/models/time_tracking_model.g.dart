// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_tracking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimeEntry _$TimeEntryFromJson(Map<String, dynamic> json) => _TimeEntry(
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

Map<String, dynamic> _$TimeEntryToJson(_TimeEntry instance) =>
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

_ClockInRequest _$ClockInRequestFromJson(Map<String, dynamic> json) =>
    _ClockInRequest(
      workerId: json['workerId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ClockInRequestToJson(_ClockInRequest instance) =>
    <String, dynamic>{
      'workerId': instance.workerId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'notes': instance.notes,
    };

_ClockOutRequest _$ClockOutRequestFromJson(Map<String, dynamic> json) =>
    _ClockOutRequest(
      timeEntryId: json['timeEntryId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ClockOutRequestToJson(_ClockOutRequest instance) =>
    <String, dynamic>{
      'timeEntryId': instance.timeEntryId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'notes': instance.notes,
    };
