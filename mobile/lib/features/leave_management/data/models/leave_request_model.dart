import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_request_model.freezed.dart';
part 'leave_request_model.g.dart';

@freezed
class LeaveRequestModel with _$LeaveRequestModel {
  const factory LeaveRequestModel({
    required String id,
    required String workerId,
    required String workerName,
    required String requestedById,
    required String leaveType,
    required String startDate,
    required String endDate,
    required int totalDays,
    required String reason,
    required String status, // PENDING, APPROVED, REJECTED, CANCELLED
    required String createdAt,
    required String updatedAt,
    String? approvedById,
    String? approvedAt,
    String? rejectionReason,
    double? dailyPayRate,
    required bool paidLeave,
    String? emergencyContact,
    String? emergencyPhone,
  }) = _LeaveRequestModel;

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestModelFromJson(json);
}

@freezed
class LeaveBalanceModel with _$LeaveBalanceModel {
  const factory LeaveBalanceModel({
    required String workerId,
    required String workerName,
    required int year,
    required int totalAnnualLeaves,
    required int usedAnnualLeaves,
    required int remainingAnnualLeaves,
    required int sickLeaves,
    required int pendingLeaves,
  }) = _LeaveBalanceModel;

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveBalanceModelFromJson(json);
}

enum LeaveType {
  annual,
  sick,
  maternity,
  paternity,
  emergency,
  unpaid,
}

enum LeaveRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}