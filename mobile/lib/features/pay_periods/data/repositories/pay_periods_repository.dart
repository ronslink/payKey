import 'package:flutter_riverpod/flutter_riverpod.dart';
// Use the canonical Freezed-based PayPeriod model
import '../../../payroll/data/models/pay_period_model.dart';
import '../../../../core/network/api_service.dart';

final payPeriodsRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PayPeriodsRepositoryImpl(apiService);
});

class PayPeriodsRepositoryImpl {
  final ApiService _apiService;
  
  PayPeriodsRepositoryImpl(this._apiService);

  Future<List<PayPeriod>> getPayPeriods({
    int page = 1,
    int limit = 100,
    PayPeriodStatus? status,
    PayPeriodFrequency? frequency,
  }) async {
    try {
      final response = await _apiService.payPeriods.getAll(queryParams: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': _statusToString(status),
        if (frequency != null) 'frequency': _frequencyToString(frequency),
      });
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
      
      // Parse with defensive null handling
      final periods = <PayPeriod>[];
      for (final json in periodsJson) {
        try {
          if (json is Map<String, dynamic>) {
            // Ensure id is not null
            if (json['id'] != null) {
              // Handle null name gracefully - generate default from date
              final adjustedJson = Map<String, dynamic>.from(json);
              if (adjustedJson['name'] == null || (adjustedJson['name'] as String).isEmpty) {
                final startDate = DateTime.tryParse(adjustedJson['startDate']?.toString() ?? '');
                if (startDate != null) {
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  adjustedJson['name'] = '${months[startDate.month - 1]} ${startDate.year}';
                } else {
                  adjustedJson['name'] = 'Pay Period';
                }
              }
              periods.add(PayPeriod.fromJson(adjustedJson));
            } else {
              print('[PayPeriods] Skipping item with null id: $json');
            }
          }
        } catch (e) {
          print('[PayPeriods] Failed to parse item: $e, data: $json');
        }
      }
      return periods;
    } catch (e) {
      throw Exception('Failed to fetch pay periods: $e');
    }
  }

  Future<PayPeriod> getPayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.getById(id);
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch pay period: $e');
    }
  }

  Future<PayPeriod> createPayPeriod({
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
        'frequency': _frequencyToString(frequency),
        if (notes != null) 'notes': notes,
      });
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create pay period: $e');
    }
  }

  Future<PayPeriod> updatePayPeriod(
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
      if (status != null) data['status'] = _statusToString(status);
      if (approvedBy != null) data['approvedBy'] = approvedBy;
      if (notes != null) data['notes'] = notes;
      
      final response = await _apiService.payPeriods.update(id, data);
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
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

  Future<PayPeriod> activatePayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.activate(id);
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to activate pay period: $e');
    }
  }

  Future<PayPeriod> processPayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.process(id);
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to process pay period: $e');
    }
  }

  Future<PayPeriod> completePayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.complete(id);
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to complete pay period: $e');
    }
  }

  Future<PayPeriod> closePayPeriod(String id) async {
    try {
      final response = await _apiService.payPeriods.close(id);
      return PayPeriod.fromJson(response.data as Map<String, dynamic>);
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

  Future<List<PayPeriod>> generatePayPeriods({
    required String userId,
    required PayPeriodFrequency frequency,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiService.payPeriods.generate(
        frequency: _frequencyToString(frequency),
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
          .map((json) => PayPeriod.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to generate pay periods: $e');
    }
  }
  
  // Helper to convert enum to API string
  String _frequencyToString(PayPeriodFrequency frequency) {
    switch (frequency) {
      case PayPeriodFrequency.weekly:
        return 'WEEKLY';
      case PayPeriodFrequency.biWeekly:
        return 'BIWEEKLY';
      case PayPeriodFrequency.monthly:
        return 'MONTHLY';
      case PayPeriodFrequency.quarterly:
        return 'QUARTERLY';
      case PayPeriodFrequency.yearly:
        return 'YEARLY';
    }
  }
  
  String _statusToString(PayPeriodStatus status) {
    switch (status) {
      case PayPeriodStatus.draft:
        return 'DRAFT';
      case PayPeriodStatus.active:
        return 'ACTIVE';
      case PayPeriodStatus.processing:
        return 'PROCESSING';
      case PayPeriodStatus.completed:
        return 'COMPLETED';
      case PayPeriodStatus.closed:
        return 'CLOSED';
      case PayPeriodStatus.cancelled:
        return 'CANCELLED';
    }
  }
}