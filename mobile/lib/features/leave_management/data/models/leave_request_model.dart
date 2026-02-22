import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_request_model.freezed.dart';
part 'leave_request_model.g.dart';

// ---------------------------------------------------------------------------
// Helpers — handle TypeORM's quirky serialisation:
//   • decimal(10,2) columns  → serialised as String e.g. "1333.33"
//   • date columns           → serialised as String "2026-04-06"
//   • timestamp columns      → serialised as ISO String
//   • boolean columns        → serialised as bool (postgres driver) or "true"
//   • int columns            → serialised as int or occasionally String
// ---------------------------------------------------------------------------

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

// date / timestamp columns always come as strings from our NestJS API
String _parseString(dynamic value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

@freezed
abstract class LeaveRequestModel with _$LeaveRequestModel {
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
    // Worker name: flat field or nested relation
    String workerName = json['workerName'] as String? ?? '';
    if (workerName.isEmpty && json['worker'] is Map) {
      workerName = (json['worker']['name']?.toString() ?? 'Unknown');
    }

    return LeaveRequestModel(
      id: _parseString(json['id']),
      workerId: _parseString(json['workerId']),
      workerName: workerName,
      // requestedById is always a UUID string from the entity
      requestedById: _parseString(json['requestedById']),
      leaveType: _parseString(json['leaveType']),
      startDate: _parseString(json['startDate']),
      endDate: _parseString(json['endDate']),
      // TypeORM int → JSON int, but guard for string just in case
      totalDays: _parseInt(json['totalDays']),
      reason: _parseString(json['reason']),
      // Enum columns serialise as their string value e.g. "PENDING"
      status: _parseString(json['status'], fallback: 'PENDING'),
      createdAt: _parseString(json['createdAt']),
      updatedAt: _parseString(json['updatedAt']),
      approvedById: json['approvedById'] as String?,
      approvedAt: json['approvedAt'] != null
          ? _parseString(json['approvedAt'])
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      // decimal(10,2) columns → TypeORM serialises as String "1333.33"
      dailyPayRate: _parseDouble(json['dailyPayRate']),
      // boolean column → true/false from pg driver, guard for "true" strings
      paidLeave: _parseBool(json['paidLeave']),
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
    );
  }
}

@freezed
abstract class LeaveBalanceModel with _$LeaveBalanceModel {
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
