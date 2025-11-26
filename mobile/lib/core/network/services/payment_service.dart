import 'package:dio/dio.dart';
import '../api_service.dart';

extension PaymentService on ApiService {
  Future<Response> initiateStkPush(String phoneNumber, double amount) async {
    return dio.post('/payments/initiate-stk', data: {
      'phoneNumber': phoneNumber,
      'amount': amount,
    });
  }

  Future<Response> sendB2CPayment(String transactionId, String phoneNumber, double amount, String remarks) async {
    return dio.post('/payments/send-b2c', data: {
      'transactionId': transactionId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'remarks': remarks,
    });
  }

  Future<Response> getTransactions() async {
    return dio.get('/transactions');
  }

  Future<Response> getTransactionById(String transactionId) async {
    return dio.get('/transactions/$transactionId');
  }
}
