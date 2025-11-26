import 'package:dio/dio.dart';
import '../api_service.dart';

extension TaxService on ApiService {
  Future<Response> calculateTax(double grossSalary) async {
    return dio.post('/taxes/calculate', data: {
      'grossSalary': grossSalary,
    });
  }

  Future<Response> getTaxSubmissions() async {
    return dio.get('/taxes/submissions');
  }

  Future<Response> markTaxAsFiled(String id) async {
    return dio.patch('/taxes/submissions/$id/file');
  }

  Future<Response> getCurrentTaxTable() async {
    return dio.get('/taxes/current');
  }

  Future<Response> getComplianceStatus() async {
    return dio.get('/taxes/compliance');
  }

  Future<Response> getTaxDeadlines() async {
    return dio.get('/taxes/deadlines');
  }

  Future<Response> generateTaxSubmission(String payPeriodId) async {
    return dio.post('/taxes/submissions/generate/$payPeriodId');
  }

  Future<Response> getTaxSubmissionByPeriod(String payPeriodId) async {
    return dio.get('/taxes/submissions/period/$payPeriodId');
  }
}
