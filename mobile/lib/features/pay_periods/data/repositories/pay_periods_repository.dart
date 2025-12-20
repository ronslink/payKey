import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pay_period_model.dart';
import '../../../../core/network/api_service.dart';

final payPeriodsRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PayPeriodsRepositoryImpl(apiService);
});

class PayPeriodsRepositoryImpl {
  final ApiService _apiService;
  
  PayPeriodsRepositoryImpl(this._apiService);

  Future<List<PayPeriodModel>> getPayPeriods({
    int page = 1,
    int limit = 10,
    PayPeriodStatus? status,
    PayPeriodFrequency? frequency,
  }) async {
    try {
      final response = await _apiService.payPeriods.getAll();
      final data = response.data;
      
      // Handle both wrapped {data: [...]} and direct array responses
      List<dynamic> periodsJson;
      if (data is Map && data.containsKey('data')) {
        periodsJson = data['data'] as List<dynamic>;
      } else if (data is List) {
        periodsJson = data;
      } else {
        return [];
      }
      
      return periodsJson
          .map((json) => PayPeriodModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pay periods: $e');
    }
  }

  Future<PayPeriodModel> getPayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.getById(id);
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch pay period: $e');
    }
  }

  Future<PayPeriodModel> createPayPeriod({
    required String name,
    required String startDate,
    required String endDate,
    String? payDate,
    required PayPeriodFrequency frequency,
    Map<String, dynamic>? notes,
  }) async {
    try {
      final response = await _apiService.payPeriods.create({
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'payDate': payDate ?? endDate,
        'frequency': frequency.value,
        if (notes != null) 'notes': notes,
      });
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create pay period: $e');
    }
  }

  Future<PayPeriodModel> updatePayPeriod(
    String id, {
    String? name,
    String? startDate,
    String? endDate,
    String? payDate,
    PayPeriodStatus? status,
    String? approvedBy,
    Map<String, dynamic>? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (startDate != null) data['startDate'] = startDate;
      if (endDate != null) data['endDate'] = endDate;
      if (payDate != null) data['payDate'] = payDate;
      if (status != null) data['status'] = status.value;
      if (approvedBy != null) data['approvedBy'] = approvedBy;
      if (notes != null) data['notes'] = notes;
      
      final response = await _apiService.payPeriods.update(id, data);
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update pay period: $e');
    }
  }

  Future<void> deletePayPeriod(String id) async {
    try {
      await _apiService.payPeriods.delete(id);
    } catch (e) {
      throw Exception('Failed to delete pay period: $e');
    }
  }

  Future<PayPeriodModel> activatePayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.activate(id);
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to activate pay period: $e');
    }
  }

  Future<PayPeriodModel> processPayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.process(id);
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to process pay period: $e');
    }
  }

  Future<PayPeriodModel> completePayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.complete(id);
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to complete pay period: $e');
    }
  }

  Future<PayPeriodModel> closePayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.close(id);
      return PayPeriodModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to close pay period: $e');
    }
  }

  Future<Map<String, dynamic>> getPayPeriodStatistics(String id) async {
    try {
      final response = await _apiService.payPeriods.getStatistics(id);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch pay period statistics: $e');
    }
  }

  Future<List<PayPeriodModel>> generatePayPeriods({
    required String userId,
    required PayPeriodFrequency frequency,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiService.payPeriods.generate(
        frequency: frequency.value,
        startDate: startDate,
        endDate: endDate,
      );
      final data = response.data;
      List<dynamic> periodsJson;
      if (data is Map && data.containsKey('data')) {
        periodsJson = data['data'] as List<dynamic>;
      } else if (data is List) {
        periodsJson = data;
      } else {
        return [];
      }
      return periodsJson
          .map((json) => PayPeriodModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to generate pay periods: $e');
    }
  }
}