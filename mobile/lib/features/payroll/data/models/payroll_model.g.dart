// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaxBreakdownImpl _$$TaxBreakdownImplFromJson(Map<String, dynamic> json) =>
    _$TaxBreakdownImpl(
      nssf: (json['nssf'] as num).toDouble(),
      nhif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      paye: (json['paye'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
    );

Map<String, dynamic> _$$TaxBreakdownImplToJson(_$TaxBreakdownImpl instance) =>
    <String, dynamic>{
      'nssf': instance.nssf,
      'nhif': instance.nhif,
      'housingLevy': instance.housingLevy,
      'paye': instance.paye,
      'totalDeductions': instance.totalDeductions,
    };

_$PayrollCalculationImpl _$$PayrollCalculationImplFromJson(
  Map<String, dynamic> json,
) => _$PayrollCalculationImpl(
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
  status: json['status'] as String? ?? 'draft',
  isEdited: json['isEdited'] as bool? ?? false,
);

Map<String, dynamic> _$$PayrollCalculationImplToJson(
  _$PayrollCalculationImpl instance,
) => <String, dynamic>{
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

_$PayrollRequestImpl _$$PayrollRequestImplFromJson(Map<String, dynamic> json) =>
    _$PayrollRequestImpl(
      workerIds: (json['workerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$PayrollRequestImplToJson(
  _$PayrollRequestImpl instance,
) => <String, dynamic>{'workerIds': instance.workerIds};

_$PayrollSummaryImpl _$$PayrollSummaryImplFromJson(Map<String, dynamic> json) =>
    _$PayrollSummaryImpl(
      calculations: (json['calculations'] as List<dynamic>)
          .map((e) => PayrollCalculation.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalGross: (json['totalGross'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
      totalNet: (json['totalNet'] as num).toDouble(),
    );

Map<String, dynamic> _$$PayrollSummaryImplToJson(
  _$PayrollSummaryImpl instance,
) => <String, dynamic>{
  'calculations': instance.calculations,
  'totalGross': instance.totalGross,
  'totalDeductions': instance.totalDeductions,
  'totalNet': instance.totalNet,
};
