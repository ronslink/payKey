// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkerPaymentResult _$WorkerPaymentResultFromJson(Map<String, dynamic> json) =>
    WorkerPaymentResult(
      workerId: json['workerId'] as String,
      workerName: json['workerName'] as String,
      success: json['success'] as bool,
      netPay: (json['netPay'] as num?)?.toDouble(),
      transactionId: json['transactionId'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$WorkerPaymentResultToJson(
  WorkerPaymentResult instance,
) => <String, dynamic>{
  'workerId': instance.workerId,
  'workerName': instance.workerName,
  'success': instance.success,
  'netPay': instance.netPay,
  'transactionId': instance.transactionId,
  'error': instance.error,
};

_TaxBreakdown _$TaxBreakdownFromJson(Map<String, dynamic> json) =>
    _TaxBreakdown(
      nssf: (json['nssf'] as num).toDouble(),
      nhif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      paye: (json['paye'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
    );

Map<String, dynamic> _$TaxBreakdownToJson(_TaxBreakdown instance) =>
    <String, dynamic>{
      'nssf': instance.nssf,
      'nhif': instance.nhif,
      'housingLevy': instance.housingLevy,
      'paye': instance.paye,
      'totalDeductions': instance.totalDeductions,
    };

_PayrollCalculation _$PayrollCalculationFromJson(Map<String, dynamic> json) =>
    _PayrollCalculation(
      id: json['id'] as String?,
      workerId: json['workerId'] as String,
      workerName: json['workerName'] as String,
      grossSalary: (json['grossSalary'] as num).toDouble(),
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0,
      otherEarnings: (json['otherEarnings'] as num?)?.toDouble() ?? 0,
      otherDeductions: (json['otherDeductions'] as num?)?.toDouble() ?? 0,
      taxBreakdown: TaxBreakdown.fromJson(
        json['taxBreakdown'] as Map<String, dynamic>,
      ),
      netPay: (json['netPay'] as num).toDouble(),
      status: json['status'] as String? ?? PayrollStatus.draft,
      isEdited: json['isEdited'] as bool? ?? false,
    );

Map<String, dynamic> _$PayrollCalculationToJson(_PayrollCalculation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workerId': instance.workerId,
      'workerName': instance.workerName,
      'grossSalary': instance.grossSalary,
      'bonuses': instance.bonuses,
      'otherEarnings': instance.otherEarnings,
      'otherDeductions': instance.otherDeductions,
      'taxBreakdown': instance.taxBreakdown,
      'netPay': instance.netPay,
      'status': instance.status,
      'isEdited': instance.isEdited,
    };

_PayrollRequest _$PayrollRequestFromJson(Map<String, dynamic> json) =>
    _PayrollRequest(
      workerIds: (json['workerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PayrollRequestToJson(_PayrollRequest instance) =>
    <String, dynamic>{'workerIds': instance.workerIds};

_PayrollSummary _$PayrollSummaryFromJson(Map<String, dynamic> json) =>
    _PayrollSummary(
      calculations: (json['calculations'] as List<dynamic>)
          .map((e) => PayrollCalculation.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalGross: (json['totalGross'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
      totalNet: (json['totalNet'] as num).toDouble(),
    );

Map<String, dynamic> _$PayrollSummaryToJson(_PayrollSummary instance) =>
    <String, dynamic>{
      'calculations': instance.calculations,
      'totalGross': instance.totalGross,
      'totalDeductions': instance.totalDeductions,
      'totalNet': instance.totalNet,
    };

_PayrollProcessingResult _$PayrollProcessingResultFromJson(
  Map<String, dynamic> json,
) => _PayrollProcessingResult(
  successCount: (json['successCount'] as num).toInt(),
  failureCount: (json['failureCount'] as num).toInt(),
  results: (json['results'] as List<dynamic>)
      .map((e) => WorkerPaymentResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  bankFile: json['bankFile'] as String?,
  failedWorkerIds:
      (json['failedWorkerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$PayrollProcessingResultToJson(
  _PayrollProcessingResult instance,
) => <String, dynamic>{
  'successCount': instance.successCount,
  'failureCount': instance.failureCount,
  'results': instance.results,
  'bankFile': instance.bankFile,
  'failedWorkerIds': instance.failedWorkerIds,
};
