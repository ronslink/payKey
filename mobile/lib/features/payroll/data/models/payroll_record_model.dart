import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_record_model.freezed.dart';
part 'payroll_record_model.g.dart';

@freezed
class PayrollRecordModel with _$PayrollRecordModel {
  const factory PayrollRecordModel({
    required String id,
    required String workerId,
    required String workerName,
    required double grossSalary,
    required double netPay,
    required String payPeriodId,
    required String paymentStatus,
    required DateTime createdAt,
    @Default([]) List<String> deductions,
    @Default(0.0) double bonuses,
    @Default(0.0) double otherEarnings,
  }) = _PayrollRecordModel;

  factory PayrollRecordModel.fromJson(Map<String, dynamic> json) =>
      _$PayrollRecordModelFromJson(json);
}