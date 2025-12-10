import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_request_model.freezed.dart';
part 'leave_request_model.g.dart';

@freezed
class LeaveRequestModel with _$LeaveRequestModel {
  const LeaveRequestModel._();
  
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

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle nested worker name
    String workerName = json['workerName'] as String? ?? '';
    if (workerName.isEmpty && json['worker'] is Map) {
      workerName = (json['worker']['name']?.toString() ?? 'Unknown');
    }
    
    // Ensure numeric fields are parsed correctly
    int totalDays = 0;
    if (json['totalDays'] is String) {
      totalDays = int.tryParse(json['totalDays']) ?? 0;
    } else if (json['totalDays'] is int) {
      totalDays = json['totalDays'];
    } else if (json['totalDays'] is num) {
      totalDays = (json['totalDays'] as num).toInt();
    }

    // Handle null fields that are required strings
    final reason = json['reason']?.toString() ?? '';
    
    return LeaveRequestModel(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      workerName: workerName,
      requestedById: json['requestedById'] as String,
      leaveType: json['leaveType'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      totalDays: totalDays,
      reason: reason,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      approvedById: json['approvedById'] as String?,
      approvedAt: json['approvedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      dailyPayRate: (json['dailyPayRate'] as num?)?.toDouble(),
      paidLeave: json['paidLeave'] as bool? ?? false,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
    );
  }
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