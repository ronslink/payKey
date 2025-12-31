import 'package:dio/dio.dart';

/// Mixin for repositories that need 403 fallback to mock data.
/// 
/// Usage:
/// ```dart
/// class LeaveManagementRepository with FeatureGatedRepository<List<LeaveRequestModel>> {
///   @override
///   String get featureKey => 'leave_management';
///
///   @override
///   List<LeaveRequestModel> getMockData() => LeaveMockData.leaveRequests;
/// 
///   Future<List<LeaveRequestModel>> getLeaveRequests() async {
///     return withMockFallback(() async {
///       final response = await _apiService.getLeaveRequests();
///       return parseResponse(response);
///     });
///   }
/// }
/// ```
mixin FeatureGatedRepository<T> {
  /// The feature key for this repository (e.g., 'leave_management')
  String get featureKey;
  
  /// Returns mock data for preview mode when a 403 is received
  T getMockData();

  /// Wraps API calls with 403 → mock data fallback.
  /// 
  /// If the API returns 403 (Forbidden), this method returns mock data instead
  /// of throwing an error, providing a graceful preview experience.
  Future<T> withMockFallback(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Feature is tier-gated, return mock data for preview
        print('[$featureKey] 403 Forbidden - returning mock data for preview');
        return getMockData();
      }
      rethrow;
    }
  }

  /// Helper for nullable returns (e.g., single entity lookups)
  Future<T?> withMockFallbackNullable(Future<T?> Function() apiCall, T mockValue) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock data for preview');
        return mockValue;
      }
      rethrow;
    }
  }
}
