import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/pay_period_model.dart';

final payPeriodRepositoryProvider = Provider((ref) => PayPeriodRepository());

class PayPeriodRepository {
  final ApiService _apiService = ApiService();

  Future<List<PayPeriod>> getPayPeriods() async {
    final response = await _apiService.getPayPeriods();
    final data = response.data as List;
    return data.map((json) => PayPeriod.fromJson(json)).toList();
  }

  Future<PayPeriod> getPayPeriodById(String payPeriodId) async {
    final response = await _apiService.getPayPeriodById(payPeriodId);
    return PayPeriod.fromJson(response.data);
  }

  Future<PayPeriod> createPayPeriod(CreatePayPeriodRequest request) async {
    final response = await _apiService.createPayPeriod({
      'name': request.name,
      'startDate': request.startDate.toIso8601String(),
      'endDate': request.endDate.toIso8601String(),
      'frequency': request.frequency.name,
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

  Future<void> activatePayPeriod(String payPeriodId) async {
    await _apiService.updatePayPeriodStatus(payPeriodId, 'activate');
  }

  Future<void> processPayPeriod(String payPeriodId) async {
    await _apiService.updatePayPeriodStatus(payPeriodId, 'process');
  }

  Future<void> completePayPeriod(String payPeriodId) async {
    await _apiService.updatePayPeriodStatus(payPeriodId, 'complete');
  }

  Future<void> closePayPeriod(String payPeriodId) async {
    await _apiService.updatePayPeriodStatus(payPeriodId, 'close');
  }

  Future<List<PayPeriod>> getCurrentPayPeriod() async {
    final response = await _apiService.getCurrentPayPeriod();
    final data = response.data as List;
    return data.map((json) => PayPeriod.fromJson(json)).toList();
  }

  Future<List<PayPeriod>> getPayPeriodsByStatus(PayPeriodStatus status) async {
    final response = await _apiService.getPayPeriodsByStatus(status.name);
    final data = response.data as List;
    return data.map((json) => PayPeriod.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getPayPeriodStatistics(String payPeriodId) async {
    final response = await _apiService.getPayPeriodStatistics(payPeriodId);
    return response.data;
  }
}
