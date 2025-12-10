import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/repositories/leave_management_repository.dart';

final leaveManagementRepositoryProvider = Provider((ref) => LeaveManagementRepository());

final leaveManagementProvider = StateNotifierProvider<LeaveManagementNotifier, AsyncValue<List<LeaveRequestModel>>>((ref) {
  final repository = ref.read(leaveManagementRepositoryProvider);
  return LeaveManagementNotifier(repository);
});

class LeaveManagementNotifier extends StateNotifier<AsyncValue<List<LeaveRequestModel>>> {
  final LeaveManagementRepository _repository;

  LeaveManagementNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLeaveRequests();
  }

  Future<void> loadLeaveRequests() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _repository.getLeaveRequests();
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createLeaveRequest(String workerId, Map<String, dynamic> requestData) async {
    try {
      final newRequest = await _repository.createLeaveRequest(workerId, requestData);
      state = AsyncValue.data([
        ...?state.value,
        newRequest,
      ]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateLeaveRequest(String requestId, Map<String, dynamic> updateData) async {
    try {
      final updatedRequest = await _repository.updateLeaveRequest(requestId, updateData);
      final requests = state.value ?? [];
      final updatedRequests = requests.map((req) => req.id == requestId ? updatedRequest : req).toList();
      state = AsyncValue.data(updatedRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteLeaveRequest(String requestId) async {
    try {
      await _repository.deleteLeaveRequest(requestId);
      final requests = state.value ?? [];
      final updatedRequests = requests.where((req) => req.id != requestId).toList();
      state = AsyncValue.data(updatedRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> approveLeaveRequest(String requestId, bool approved, {String? comments}) async {
    try {
      await _repository.approveLeaveRequest(requestId, approved, comments: comments);
      await loadLeaveRequests(); // Reload to get updated data
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final workerLeaveRequestsProvider = StateNotifierProvider.family<WorkerLeaveRequestsNotifier, AsyncValue<List<LeaveRequestModel>>, String>((ref, workerId) {
  final repository = ref.read(leaveManagementRepositoryProvider);
  return WorkerLeaveRequestsNotifier(repository, workerId);
});

class WorkerLeaveRequestsNotifier extends StateNotifier<AsyncValue<List<LeaveRequestModel>>> {
  final LeaveManagementRepository _repository;
  final String _workerId;

  WorkerLeaveRequestsNotifier(this._repository, this._workerId) : super(const AsyncValue.loading()) {
    loadWorkerLeaveRequests();
  }

  Future<void> loadWorkerLeaveRequests() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _repository.getWorkerLeaveRequests(_workerId);
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final leaveBalanceProvider = FutureProvider.family<LeaveBalanceModel, String>((ref, workerId) async {
  final repository = ref.read(leaveManagementRepositoryProvider);
  final balanceMap = await repository.getLeaveBalance(workerId);
  
  // Convert Map to LeaveBalanceModel - assuming the map has the expected keys
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

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}