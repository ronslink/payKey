import '../models/leave_request_model.dart';

/// Mock data for Leave Management feature preview mode.
/// 
/// This data is shown to users who don't have PLATINUM subscription
/// but are viewing the Leave Management feature in preview mode.
class LeaveMockData {
  /// Sample leave requests for preview mode
  static List<LeaveRequestModel> get leaveRequests => [
    LeaveRequestModel(
      id: 'preview-lr-001',
      workerId: 'preview-worker-001',
      workerName: 'Jane Doe (Sample)',
      requestedById: 'preview-user',
      leaveType: 'ANNUAL',
      startDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      endDate: DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      totalDays: 3,
      reason: 'Family vacation - This is sample data',
      status: 'PENDING',
      paidLeave: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    ),
    LeaveRequestModel(
      id: 'preview-lr-002',
      workerId: 'preview-worker-002',
      workerName: 'John Smith (Sample)',
      requestedById: 'preview-user',
      leaveType: 'SICK',
      startDate: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      endDate: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      totalDays: 1,
      reason: 'Doctor appointment - This is sample data',
      status: 'APPROVED',
      paidLeave: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      approvedAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
    ),
    LeaveRequestModel(
      id: 'preview-lr-003',
      workerId: 'preview-worker-001',
      workerName: 'Jane Doe (Sample)',
      requestedById: 'preview-user',
      leaveType: 'MATERNITY',
      startDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      endDate: DateTime.now().add(const Duration(days: 120)).toIso8601String(),
      totalDays: 90,
      reason: 'Maternity leave - This is sample data',
      status: 'PENDING',
      paidLeave: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    ),
  ];

  /// Sample leave balance for preview mode
  static LeaveBalanceModel getLeaveBalance(String workerId) => LeaveBalanceModel(
    workerId: workerId.isNotEmpty ? workerId : 'preview-worker-001',
    workerName: 'Sample Worker',
    year: DateTime.now().year,
    totalAnnualLeaves: 21,
    usedAnnualLeaves: 5,
    remainingAnnualLeaves: 16,
    sickLeaves: 10,
    pendingLeaves: 2,
  );
}
