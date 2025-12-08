import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/payroll_record_model.dart';

final payrollRecordsRepositoryProvider = Provider<PayrollRecordsRepository>((ref) => PayrollRecordsRepository());

class PayrollRecordsRepository {
  final ApiService _apiService = ApiService();

  Future<List<PayrollRecordModel>> getPayrollRecords() async {
    try {
      final response = await _apiService.getPayrollRecords();
      final data = response.data as List;
      
      return data.map((json) => PayrollRecordModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to fetch payroll records: $e');
    }
  }

  Future<void> updatePayrollStatus(String recordId, String status, {String? paymentDate}) async {
    try {
      await _apiService.updatePayrollStatus(recordId, status, paymentDate: paymentDate);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to update payroll status: $e');
    }
  }

  Future<void> deletePayrollRecord(String recordId) async {
    try {
      await _apiService.deletePayrollRecord(recordId);
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to delete payroll record: $e');
    }
  }
}