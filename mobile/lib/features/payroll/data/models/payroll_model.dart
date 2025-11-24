import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_model.freezed.dart';
part 'payroll_model.g.dart';

@freezed
class TaxBreakdown with _$TaxBreakdown {
  const factory TaxBreakdown({
    required double nssf,
    required double nhif,
    required double housingLevy,
    required double paye,
    required double totalDeductions,
  }) = _TaxBreakdown;

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) =>
      _$TaxBreakdownFromJson(json);
}

@freezed
class PayrollCalculation with _$PayrollCalculation {
  const factory PayrollCalculation({
    String? id, // Optional because initial calculation won't have it
    required String workerId,
    required String workerName,
    required double grossSalary,
    @Default(0) double bonuses,
    @Default(0) double otherEarnings,
    @Default(0) double otherDeductions,
    required TaxBreakdown taxBreakdown,
    required double netPay,
    @Default('draft') String status,
    @Default(false) bool isEdited,
  }) = _PayrollCalculation;

  factory PayrollCalculation.fromJson(Map<String, dynamic> json) =>
      _$PayrollCalculationFromJson(json);
}

@freezed
class PayrollRequest with _$PayrollRequest {
  const factory PayrollRequest({
    required List<String> workerIds,
  }) = _PayrollRequest;

  factory PayrollRequest.fromJson(Map<String, dynamic> json) =>
      _$PayrollRequestFromJson(json);
}

@freezed
class PayrollSummary with _$PayrollSummary {
  const factory PayrollSummary({
    required List<PayrollCalculation> calculations,
    required double totalGross,
    required double totalDeductions,
    required double totalNet,
  }) = _PayrollSummary;

  factory PayrollSummary.fromJson(Map<String, dynamic> json) =>
      _$PayrollSummaryFromJson(json);
}
