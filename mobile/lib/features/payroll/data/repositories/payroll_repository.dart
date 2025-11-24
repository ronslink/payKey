import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../payments/data/models/payment_model.dart';
import '../models/payroll_model.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(
    ref.read(apiClientProvider),
    const FlutterSecureStorage(),
  );
});

class PayrollRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  PayrollRepository(this._dio, this._storage);

  Future<List<PayrollCalculation>> calculatePayroll(
    List<String> workerIds, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.post(
        '/payroll/calculate',
        data: {
          'workerIds': workerIds,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      // Handle both full response and list response
      final data = response.data;
      List<dynamic> items;
      
      if (data is Map && data.containsKey('payrollItems')) {
        items = data['payrollItems'];
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }

      return items
          .map((json) => PayrollCalculation.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> processPayroll(
    List<String> workerIds,
    String payPeriodId,
  ) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.post(
        '/payroll/batch/process',
        data: {
          'workerIds': workerIds,
          'processDate': DateTime.now().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PayrollCalculation>> saveDraftPayroll(
    String payPeriodId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.post(
        '/payroll/draft',
        data: {
          'payPeriodId': payPeriodId,
          'payrollItems': items,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      return (response.data as List)
          .map((json) => PayrollCalculation.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PayrollCalculation> updatePayrollItem(
    String payrollRecordId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.patch(
        '/payroll/draft/$payrollRecordId',
        data: updates,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      return PayrollCalculation.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PayrollCalculation>> getDraftPayroll(String payPeriodId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.get(
        '/payroll/draft/$payPeriodId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      return (response.data as List)
          .map((json) => PayrollCalculation.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> finalizePayroll(String payPeriodId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      await _dio.post(
        '/payroll/finalize/$payPeriodId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> downloadPayslip(String payrollRecordId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.get<List<int>>(
        '/payroll/payslip/$payrollRecordId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );
      return response.data ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return Exception(error.response?.data['message'] ?? 'An error occurred');
      }
      return Exception(error.message);
    }
    return Exception(error.toString());
  }
}
