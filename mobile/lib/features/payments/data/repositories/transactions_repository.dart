import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/transaction_model.dart';

final transactionsRepositoryProvider = Provider((ref) => TransactionsRepository());

class TransactionsRepository {
  final ApiService _apiService = ApiService();

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _apiService.getTransactions();
      final data = response.data as List;
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<TransactionModel> getTransactionById(String transactionId) async {
    try {
      final response = await _apiService.getTransactionById(transactionId);
      return TransactionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch transaction: $e');
    }
  }
}