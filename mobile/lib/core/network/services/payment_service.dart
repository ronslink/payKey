import 'package:dio/dio.dart';
import '../api_service.dart';

extension PaymentService on ApiService {
  // Unified Payment Dashboard
  Future<Response> getPaymentDashboard() async {
    return dio.get('/payments/unified/dashboard');
  }

  Future<Response> getPaymentMethods() async {
    return dio.get('/payments/unified/methods');
  }

  // M-Pesa Payments
  Future<Response> initiateMpesaTopup(String phoneNumber, double amount) async {
    return dio.post('/payments/unified/mpesa/topup', data: {
      'phoneNumber': phoneNumber,
      'amount': amount,
    });
  }

  // Tax Payments
  Future<Response> getTaxPaymentSummary() async {
    return dio.get('/payments/unified/tax-payments/summary');
  }

  Future<Response> recordTaxPayment({
    required String taxType,
    required double amount,
    String? paymentDate,
    required String reference,
  }) async {
    return dio.post('/payments/unified/tax-payments/record', data: {
      'taxType': taxType,
      'amount': amount,
      'paymentDate': paymentDate,
      'reference': reference,
    });
  }

  // Legacy M-Pesa methods (for backward compatibility)
  Future<Response> initiateStkPush(String phoneNumber, double amount) async {
    return initiateMpesaTopup(phoneNumber, amount);
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

  Future<Response> initiateCheckoutTopup(double amount) async {
    return dio.post('/payments/checkout/topup', data: {
      'amount': amount,
    });
  }
}
