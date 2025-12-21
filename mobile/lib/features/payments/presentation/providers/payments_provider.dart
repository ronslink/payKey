import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../../../core/network/api_service.dart';

final transactionsRepositoryProvider = Provider((ref) => TransactionsRepository());

// API Service Provider
final apiServiceProvider = Provider((ref) => ApiService());

// Payment Dashboard Provider
final paymentDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getPaymentDashboard();
  return response.data;
});

// Payment Methods Provider
final paymentMethodsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getPaymentMethods();
  return response.data;
});

// Tax Payment Summary Provider
final taxPaymentSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getTaxPaymentSummary();
  return response.data;
});

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, void>(PaymentsNotifier.new);

class PaymentsNotifier extends AsyncNotifier<void> {
  late final ApiService _apiService;

  @override
  FutureOr<void> build() {
    _apiService = ref.watch(apiServiceProvider);
  }

  Future<Map<String, dynamic>> initiatePayment(
    String phoneNumber, 
    double amount, {
    String? accountReference, 
    String? transactionDesc,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.initiateMpesaTopup(
        phoneNumber, 
        amount,
        accountReference: accountReference,
        transactionDesc: transactionDesc,
      );
      
      state = const AsyncValue.data(null);
      return response.data;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordTaxPayment({
    required String taxType,
    required double amount,
    String? paymentDate,
    required String reference,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.recordTaxPayment(
        taxType: taxType,
        amount: amount,
        paymentDate: paymentDate,
        reference: reference,
      );
      
      state = const AsyncValue.data(null);
      return response.data;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactions() async {
    try {
      final response = await _apiService.getTransactions();
      return response.data;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
      rethrow;
    }
  }
}
