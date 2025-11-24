import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pay_period_model.dart';
import '../../../../core/network/api_client.dart';

class PayPeriodRepository {
  final Dio _dio;
  
  PayPeriodRepository(this._dio);
  
  Future<List<PayPeriod>> getPayPeriods() async {
    try {
      final response = await _dio.get('/payroll/pay-periods');
      return (response.data as List)
          .map((e) => PayPeriod.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> createPayPeriod(int year, int month) async {
    try {
      await _dio.post('/payroll/pay-periods', data: {
        'year': year,
        'month': month,
      });
    } catch (e) {
      rethrow;
    }
  }
}

final payPeriodRepositoryProvider = Provider<PayPeriodRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PayPeriodRepository(dio);
});
