import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/pay_period_model.dart';

final payPeriodRepositoryProvider = Provider((ref) => PayPeriodRepository());

class PayPeriodRepository {
  final ApiService _apiService = ApiService();

  /// Fetch all pay periods (no status filter).
  /// Use this for admin or overview screens where you want to show all periods.
  Future<List<PayPeriod>> getPayPeriods() async {
    try {
      print('Fetching pay periods...');
      final response = await _apiService.getPayPeriods();
      print('Pay periods response: ${response.data}');
      final raw = response.data;
      final data = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] : []);
      
      print('Parsing ${data.length} pay periods...');
      final parsedPeriods = (data as List).map((json) {
        try {
          return PayPeriod.fromJson(Map<String, dynamic>.from(json as Map));
        } catch (e) {
          print('Error parsing pay period: $e');
          print('JSON: $json');
          return null;
        }
      }).where((item) => item != null).cast<PayPeriod>().toList();
      
      return parsedPeriods;
    } catch (e, stack) {
      print('Error in getPayPeriods: $e');
      print(stack);
      rethrow;
    }
  }

  /// Fetch pay periods by status.
  /// Use this for dashboards or filtered views (e.g., only active or draft periods).
  Future<List<PayPeriod>> getPayPeriodsByStatus(PayPeriodStatus status) async {
    try {
      print('Fetching pay periods by status: $status');
      final response = await _apiService.getPayPeriodsByStatus(status.name.toUpperCase());
      final raw = response.data;
      final data = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] : []);
      return (data as List).map((json) {
        try {
          return PayPeriod.fromJson(Map<String, dynamic>.from(json as Map));
        } catch (e) {
          print('Error parsing pay period in status filter: $e');
          return null;
        }
      }).where((item) => item != null).cast<PayPeriod>().toList();
    } catch (e) {
      print('Error in getPayPeriodsByStatus: $e');
      rethrow;
    }
  }

  Future<PayPeriod> getPayPeriodById(String payPeriodId) async {
    final response = await _apiService.getPayPeriodById(payPeriodId);
    return PayPeriod.fromJson(response.data);
  }

  Future<PayPeriod> createPayPeriod(CreatePayPeriodRequest request) async {
    final response = await _apiService.createPayPeriod({
      'name': request.name,
      'startDate': request.startDate.toIso8601String().split('T')[0],
      'endDate': request.endDate.toIso8601String().split('T')[0],
      'frequency': request.frequency.name.toUpperCase(),
      if (request.notes != null) 'notes': request.notes,
    });
    return PayPeriod.fromJson(response.data);
  }

  Future<PayPeriod> updatePayPeriod(String payPeriodId, UpdatePayPeriodRequest request) async {
    final updateData = <String, dynamic>{};
    
    if (request.name != null) updateData['name'] = request.name!;
    if (request.startDate != null) updateData['startDate'] = request.startDate!.toIso8601String();
    if (request.endDate != null) updateData['endDate'] = request.endDate!.toIso8601String();
    if (request.frequency != null) updateData['frequency'] = request.frequency!.name;
    if (request.status != null) updateData['status'] = request.status!.name;
    if (request.notes != null) updateData['notes'] = request.notes!;

    final response = await _apiService.updatePayPeriod(payPeriodId, updateData);
    return PayPeriod.fromJson(response.data);
  }

  Future<void> deletePayPeriod(String payPeriodId) async {
    await _apiService.deletePayPeriod(payPeriodId);
  }

  Future<PayPeriod> activatePayPeriod(String payPeriodId) async {
    await _apiService.activatePayPeriod(payPeriodId);
    return await getPayPeriodById(payPeriodId);
  }

  Future<PayPeriod> processPayPeriod(String payPeriodId) async {
    await _apiService.processPayPeriod(payPeriodId);
    return await getPayPeriodById(payPeriodId);
  }

  Future<PayPeriod> completePayPeriod(String payPeriodId) async {
    await _apiService.completePayPeriod(payPeriodId);
    return await getPayPeriodById(payPeriodId);
  }

  Future<PayPeriod> closePayPeriod(String payPeriodId) async {
    await _apiService.closePayPeriod(payPeriodId);
    return await getPayPeriodById(payPeriodId);
  }

  Future<void> updatePayPeriodStatus(String payPeriodId, String action) async {
    await _apiService.updatePayPeriodStatus(payPeriodId, action);
  }

  Future<List<PayPeriod>> getCurrentPayPeriod() async {
    final response = await _apiService.getCurrentPayPeriod();
    final data = response.data as List;
    return data.map((json) => PayPeriod.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PayPeriod> getPayPeriod(String payPeriodId) async {
    final response = await _apiService.getPayPeriodById(payPeriodId);
    return PayPeriod.fromJson(response.data);
  }

  Future<void> generatePayslips(String payPeriodId) async {
    await _apiService.post('/payroll/payslips/generate/$payPeriodId', data: {});
  }

  // Duplicate removed. Use the version above that handles both array and {data: [...]} responses.

  Future<Map<String, dynamic>> getPayPeriodStatistics(String payPeriodId) async {
    final response = await _apiService.getPayPeriodStatistics(payPeriodId);
    return response.data;
  }
}
