// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PayrollRecordModelImpl _$$PayrollRecordModelImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollRecordModelImpl(
  id: json['id'] as String,
  workerId: json['workerId'] as String,
  workerName: json['workerName'] as String,
  grossSalary: (json['grossSalary'] as num).toDouble(),
  netPay: (json['netPay'] as num).toDouble(),
  payPeriodId: json['payPeriodId'] as String,
  paymentStatus: json['paymentStatus'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  deductions:
      (json['deductions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
  otherEarnings: (json['otherEarnings'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$PayrollRecordModelImplToJson(
  _$PayrollRecordModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'workerId': instance.workerId,
  'workerName': instance.workerName,
  'grossSalary': instance.grossSalary,
  'netPay': instance.netPay,
  'payPeriodId': instance.payPeriodId,
  'paymentStatus': instance.paymentStatus,
  'createdAt': instance.createdAt.toIso8601String(),
  'deductions': instance.deductions,
  'bonuses': instance.bonuses,
  'otherEarnings': instance.otherEarnings,
};
