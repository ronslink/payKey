import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/leave_request_model.dart';
import '../mock/leave_mock_data.dart';

final leaveManagementRepositoryProvider = Provider((ref) => LeaveManagementRepository());

/// Repository for leave management with 403 fallback to mock data.
/// 
/// When the user doesn't have PLATINUM subscription, the backend returns 403.
/// This repository catches those errors and returns mock data for preview mode.
class LeaveManagementRepository {
  final ApiService _apiService = ApiService();

  /// Feature key for gating
  static const String featureKey = 'leave_management';

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    try {
      final response = await _apiService.getLeaveRequests();
      final data = response.data as List;
      return data.map((json) => LeaveRequestModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock leave requests');
        return LeaveMockData.leaveRequests;
      }
      rethrow;
    }
  }

  Future<List<LeaveRequestModel>> getWorkerLeaveRequests(String workerId) async {
    try {
      final response = await _apiService.getWorkerLeaveRequests(workerId);
      final data = response.data as List;
      return data.map((json) => LeaveRequestModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock worker leave requests');
        return LeaveMockData.leaveRequests
            .where((r) => r.workerId.startsWith('preview'))
            .toList();
      }
      rethrow;
    }
  }

  Future<LeaveRequestModel> createLeaveRequest(
    String workerId,
    Map<String, dynamic> leaveRequestData,
  ) async {
    try {
      final response = await _apiService.createLeaveRequest(workerId, leaveRequestData);
      return LeaveRequestModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // In preview mode, show a message that they can't create real requests
        throw Exception('Upgrade to PLATINUM to create leave requests');
      }
      rethrow;
    }
  }

  Future<LeaveRequestModel> updateLeaveRequest(
    String leaveRequestId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiService.updateLeaveRequest(leaveRequestId, updateData);
      return LeaveRequestModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to manage leave requests');
      }
      rethrow;
    }
  }

  Future<void> deleteLeaveRequest(String leaveRequestId) async {
    try {
      await _apiService.deleteLeaveRequest(leaveRequestId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to delete leave requests');
      }
      rethrow;
    }
  }

  Future<void> approveLeaveRequest(String leaveRequestId, bool approved, {String? comments}) async {
    try {
      await _apiService.approveLeaveRequest(leaveRequestId, approved, comments: comments);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to approve leave requests');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLeaveBalance(String workerId) async {
    try {
      final response = await _apiService.getLeaveBalance(workerId);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock leave balance');
        final mockBalance = LeaveMockData.getLeaveBalance(workerId);
        return {
          'workerId': mockBalance.workerId,
          'workerName': mockBalance.workerName,
          'year': mockBalance.year,
          'totalAnnualLeaves': mockBalance.totalAnnualLeaves,
          'usedAnnualLeaves': mockBalance.usedAnnualLeaves,
          'remainingAnnualLeaves': mockBalance.remainingAnnualLeaves,
          'sickLeaves': mockBalance.sickLeaves,
          'pendingLeaves': mockBalance.pendingLeaves,
        };
      }
      rethrow;
    }
  }
}