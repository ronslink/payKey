// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaveRequestModelImpl _$$LeaveRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$LeaveRequestModelImpl(
  id: json['id'] as String,
  workerId: json['workerId'] as String,
  workerName: json['workerName'] as String,
  requestedById: json['requestedById'] as String,
  leaveType: json['leaveType'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  totalDays: (json['totalDays'] as num).toInt(),
  reason: json['reason'] as String,
  status: json['status'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  approvedById: json['approvedById'] as String?,
  approvedAt: json['approvedAt'] as String?,
  rejectionReason: json['rejectionReason'] as String?,
  dailyPayRate: (json['dailyPayRate'] as num?)?.toDouble(),
  paidLeave: json['paidLeave'] as bool,
  emergencyContact: json['emergencyContact'] as String?,
  emergencyPhone: json['emergencyPhone'] as String?,
);

Map<String, dynamic> _$$LeaveRequestModelImplToJson(
  _$LeaveRequestModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'workerId': instance.workerId,
  'workerName': instance.workerName,
  'requestedById': instance.requestedById,
  'leaveType': instance.leaveType,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'totalDays': instance.totalDays,
  'reason': instance.reason,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'approvedById': instance.approvedById,
  'approvedAt': instance.approvedAt,
  'rejectionReason': instance.rejectionReason,
  'dailyPayRate': instance.dailyPayRate,
  'paidLeave': instance.paidLeave,
  'emergencyContact': instance.emergencyContact,
  'emergencyPhone': instance.emergencyPhone,
};

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
