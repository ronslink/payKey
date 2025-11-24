import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/pay_period_model.dart';

final payPeriodRepositoryProvider = Provider<PayPeriodRepository>((ref) {
  return PayPeriodRepository(ref.read(apiClientProvider));
});

class PayPeriodRepository {
  final ApiClient _apiClient;

  PayPeriodRepository(this._apiClient);

  Future<List<PayPeriod>> getPayPeriods() async {
    final response = await _apiClient.get('/payroll/pay-periods');
    return (response.data as List)
        .map((e) => PayPeriod.fromJson(e))
        .toList();
  }

  Future<PayPeriod> createPayPeriod(int year, int month) async {
    final response = await _apiClient.post('/payroll/pay-periods', data: {
      'year': year,
      'month': month,
    });
    return PayPeriod.fromJson(response.data);
  }

  Future<PayPeriod> getPayPeriod(String id) async {
    final response = await _apiClient.get('/payroll/pay-periods/$id');
    return PayPeriod.fromJson(response.data);
  }
}
