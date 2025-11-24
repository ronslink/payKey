// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_payroll_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkerPayrollResultImpl _$$WorkerPayrollResultImplFromJson(
  Map<String, dynamic> json,
) => _$WorkerPayrollResultImpl(
  workerId: json['workerId'] as String,
  workerName: json['workerName'] as String,
  success: json['success'] as bool,
  grossSalary: (json['grossSalary'] as num?)?.toDouble(),
  netPay: (json['netPay'] as num?)?.toDouble(),
  transactionId: json['transactionId'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$$WorkerPayrollResultImplToJson(
  _$WorkerPayrollResultImpl instance,
) => <String, dynamic>{
  'workerId': instance.workerId,
  'workerName': instance.workerName,
  'success': instance.success,
  'grossSalary': instance.grossSalary,
  'netPay': instance.netPay,
  'transactionId': instance.transactionId,
  'error': instance.error,
};

_$BatchPayrollResultImpl _$$BatchPayrollResultImplFromJson(
  Map<String, dynamic> json,
) => _$BatchPayrollResultImpl(
  totalWorkers: (json['totalWorkers'] as num).toInt(),
  successCount: (json['successCount'] as num).toInt(),
  failureCount: (json['failureCount'] as num).toInt(),
  totalGross: (json['totalGross'] as num).toDouble(),
  totalNet: (json['totalNet'] as num).toDouble(),
  results: (json['results'] as List<dynamic>)
      .map((e) => WorkerPayrollResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  processedAt: json['processedAt'] as String,
);

Map<String, dynamic> _$$BatchPayrollResultImplToJson(
  _$BatchPayrollResultImpl instance,
) => <String, dynamic>{
  'totalWorkers': instance.totalWorkers,
  'successCount': instance.successCount,
  'failureCount': instance.failureCount,
  'totalGross': instance.totalGross,
  'totalNet': instance.totalNet,
  'results': instance.results,
  'processedAt': instance.processedAt,
};
