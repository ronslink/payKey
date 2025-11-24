import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../models/payment_model.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(
    ref.read(apiClientProvider),
    ref.read(storageProvider),
  );
});

final storageProvider = Provider((ref) => const FlutterSecureStorage());

class PaymentsRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  PaymentsRepository(this._dio, this._storage);

  Future<PaymentResponse> initiateTopup(String phoneNumber, double amount) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.post(
        '/payments/topup',
        data: {'phoneNumber': phoneNumber, 'amount': amount},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PaymentResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.get(
        '/transactions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (response.data as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return Exception(error.response?.data['message'] ?? 'An error occurred');
      }
      return Exception(error.message);
    }
    return Exception(error.toString());
  }
}
