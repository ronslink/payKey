// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaveBalanceModelImpl _$$LeaveBalanceModelImplFromJson(
  Map<String, dynamic> json,
) => _$LeaveBalanceModelImpl(
  workerId: json['workerId'] as String,
  workerName: json['workerName'] as String,
  year: (json['year'] as num).toInt(),
  totalAnnualLeaves: (json['totalAnnualLeaves'] as num).toInt(),
  usedAnnualLeaves: (json['usedAnnualLeaves'] as num).toInt(),
  remainingAnnualLeaves: (json['remainingAnnualLeaves'] as num).toInt(),
  sickLeaves: (json['sickLeaves'] as num).toInt(),
  pendingLeaves: (json['pendingLeaves'] as num).toInt(),
);

Map<String, dynamic> _$$LeaveBalanceModelImplToJson(
  _$LeaveBalanceModelImpl instance,
) => <String, dynamic>{
  'workerId': instance.workerId,
  'workerName': instance.workerName,
  'year': instance.year,
  'totalAnnualLeaves': instance.totalAnnualLeaves,
  'usedAnnualLeaves': instance.usedAnnualLeaves,
  'remainingAnnualLeaves': instance.remainingAnnualLeaves,
  'sickLeaves': instance.sickLeaves,
  'pendingLeaves': instance.pendingLeaves,
};
