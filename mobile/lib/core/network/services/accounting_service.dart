import 'package:dio/dio.dart';
import '../api_service.dart';

extension AccountingService on ApiService {
  Future<Response> exportPayrollToCSV(String payPeriodId) async {
    return dio.post('/accounting/export/$payPeriodId', data: {'format': 'CSV'});
  }

  Future<Response> getAccountingFormats() async {
    return dio.get('/accounting/formats');
  }

  Future<Response> getAccountMappings() async {
    return dio.get('/accounting/mappings');
  }

  Future<Response> saveAccountMappings(Map<String, dynamic> mappings) async {
    return dio.post('/accounting/mappings', data: mappings);
  }
}
