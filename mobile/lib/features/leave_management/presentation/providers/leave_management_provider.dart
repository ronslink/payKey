import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/leave_request_model.dart';
import '../../data/repositories/leave_management_repository.dart';

// =============================================================================
// Providers
// =============================================================================

/// Provides the leave management repository instance.
final leaveManagementRepositoryProvider = Provider<LeaveManagementRepository>(
  (ref) => LeaveManagementRepository(),
);

/// Manages all leave requests across the application.
final leaveManagementProvider =
    AsyncNotifierProvider<LeaveManagementNotifier, List<LeaveRequestModel>>(
  LeaveManagementNotifier.new,
);

/// Manages leave requests for a specific worker.
final workerLeaveRequestsProvider = FutureProvider.family<List<LeaveRequestModel>, String>((ref, workerId) async {
  final repository = ref.watch(leaveManagementRepositoryProvider);
  return repository.getWorkerLeaveRequests(workerId);
});

/// Fetches leave balance for a specific worker.
final leaveBalanceProvider =
    FutureProvider.family<LeaveBalanceModel, String>((ref, workerId) async {
  final repository = ref.read(leaveManagementRepositoryProvider);
  final balanceMap = await repository.getLeaveBalance(workerId);

  return LeaveBalanceModel(
    workerId: workerId,
    workerName: balanceMap['workerName'] as String? ?? 'Unknown Worker',
    year: _parseInt(balanceMap['year']),
    totalAnnualLeaves: _parseInt(balanceMap['totalAnnualLeaves']),
    usedAnnualLeaves: _parseInt(balanceMap['usedAnnualLeaves']),
    remainingAnnualLeaves: _parseInt(balanceMap['remainingAnnualLeaves']),
    sickLeaves: _parseInt(balanceMap['sickLeaves']),
    pendingLeaves: _parseInt(balanceMap['pendingLeaves']),
  );
});

// =============================================================================
// Notifiers
// =============================================================================

/// Notifier for managing all leave requests.
class LeaveManagementNotifier extends AsyncNotifier<List<LeaveRequestModel>> {
  late LeaveManagementRepository _repository;

  @override
  FutureOr<List<LeaveRequestModel>> build() {
    _repository = ref.watch(leaveManagementRepositoryProvider);
    return _loadLeaveRequests();
  }

  Future<List<LeaveRequestModel>> _loadLeaveRequests() {
    return _repository.getLeaveRequests();
  }

  /// Reloads all leave requests from the repository.
  Future<void> loadLeaveRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadLeaveRequests());
  }

  /// Creates a new leave request for a worker.
  Future<void> createLeaveRequest(
    String workerId,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final newRequest = await _repository.createLeaveRequest(
        workerId,
        requestData,
      );
      state = AsyncValue.data([
        ...?state.value,
        newRequest,
      ]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing leave request.
  Future<void> updateLeaveRequest(
    String requestId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final updatedRequest = await _repository.updateLeaveRequest(
        requestId,
        updateData,
      );
      final requests = state.value ?? [];
      final updatedRequests = requests
          .map((req) => req.id == requestId ? updatedRequest : req)
          .toList();
      state = AsyncValue.data(updatedRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Deletes a leave request.
  Future<void> deleteLeaveRequest(String requestId) async {
    try {
      await _repository.deleteLeaveRequest(requestId);
      final requests = state.value ?? [];
      final updatedRequests =
          requests.where((req) => req.id != requestId).toList();
      state = AsyncValue.data(updatedRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Approves or rejects a leave request.
  Future<void> approveLeaveRequest(
    String requestId,
    bool approved, {
    String? comments,
  }) async {
    try {
      await _repository.approveLeaveRequest(
        requestId,
        approved,
        comments: comments,
      );
      await loadLeaveRequests();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

// =============================================================================
// Utilities
// =============================================================================

/// Safely parses a dynamic value to an integer.
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}