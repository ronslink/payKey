import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch_payroll_model.freezed.dart';
part 'batch_payroll_model.g.dart';

@freezed
class WorkerPayrollResult with _$WorkerPayrollResult {
  const factory WorkerPayrollResult({
    required String workerId,
    required String workerName,
    required bool success,
    double? grossSalary,
    double? netPay,
    String? transactionId,
    String? error,
  }) = _WorkerPayrollResult;

  factory WorkerPayrollResult.fromJson(Map<String, dynamic> json) =>
      _$WorkerPayrollResultFromJson(json);
}

@freezed
class BatchPayrollResult with _$BatchPayrollResult {
  const factory BatchPayrollResult({
    required int totalWorkers,
    required int successCount,
    required int failureCount,
    required double totalGross,
    required double totalNet,
    required List<WorkerPayrollResult> results,
    required String processedAt,
  }) = _BatchPayrollResult;

  factory BatchPayrollResult.fromJson(Map<String, dynamic> json) =>
      _$BatchPayrollResultFromJson(json);
}
