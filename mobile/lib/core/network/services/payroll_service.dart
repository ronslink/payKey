import 'package:dio/dio.dart';
import '../api_service.dart';

extension PayrollService on ApiService {
  Future<Response> getPayrollRecords() async {
    return dio.get('/payroll-records');
  }

  Future<Response> updatePayrollStatus(String recordId, String status, String? paymentDate) async {
    return dio.patch('/payroll-records/$recordId/status', data: {
      'status': status,
      if (paymentDate != null) 'paymentDate': paymentDate,
    });
  }

  Future<Response> deletePayrollRecord(String recordId) async {
    return dio.delete('/payroll-records/$recordId');
  }

  Future<Response> saveDraftPayroll(String payPeriodId, List<Map<String, dynamic>> items) async {
    return dio.post('/payroll/draft', data: {
      'payPeriodId': payPeriodId,
      'payrollItems': items,
    });
  }

  Future<Response> updatePayrollItem(String payrollRecordId, Map<String, dynamic> updates) async {
    return dio.patch('/payroll/draft/$payrollRecordId', data: updates);
  }

  Future<Response> getDraftPayroll(String payPeriodId) async {
    return dio.get('/payroll/draft/$payPeriodId');
  }

  Future<Response> finalizePayroll(String payPeriodId) async {
    return dio.post('/payroll/finalize/$payPeriodId');
  }

  Future<List<int>> downloadPayslip(String payrollRecordId) async {
    try {
      final response = await dio.get<List<int>>(
        '/payroll/payslip/$payrollRecordId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }
}
