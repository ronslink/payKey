import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/leave_request_model.dart';

final leaveManagementRepositoryProvider = Provider((ref) => LeaveManagementRepository());

class LeaveManagementRepository {
  final ApiService _apiService = ApiService();

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final response = await _apiService.getLeaveRequests();
    final data = response.data as List;
    return data.map((json) => LeaveRequestModel.fromJson(json)).toList();
  }

  Future<List<LeaveRequestModel>> getWorkerLeaveRequests(String workerId) async {
    final response = await _apiService.getWorkerLeaveRequests(workerId);
    final data = response.data as List;
    return data.map((json) => LeaveRequestModel.fromJson(json)).toList();
  }

  Future<LeaveRequestModel> createLeaveRequest(
    String workerId,
    Map<String, dynamic> leaveRequestData,
  ) async {
    final response = await _apiService.createLeaveRequest(workerId, leaveRequestData);
    return LeaveRequestModel.fromJson(response.data);
  }

  Future<LeaveRequestModel> updateLeaveRequest(
    String leaveRequestId,
    Map<String, dynamic> updateData,
  ) async {
    final response = await _apiService.updateLeaveRequest(leaveRequestId, updateData);
    return LeaveRequestModel.fromJson(response.data);
  }

  Future<void> deleteLeaveRequest(String leaveRequestId) async {
    await _apiService.deleteLeaveRequest(leaveRequestId);
  }

  Future<void> approveLeaveRequest(String leaveRequestId, bool approved, {String? comments}) async {
    await _apiService.approveLeaveRequest(leaveRequestId, approved, comments: comments);
  }

  Future<Map<String, int>> getLeaveBalance(String workerId) async {
    final response = await _apiService.getLeaveBalance(workerId);
    return response.data as Map<String, int>;
  }
}