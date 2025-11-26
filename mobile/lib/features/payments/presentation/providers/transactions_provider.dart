import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transactions_repository.dart';

final transactionsRepositoryProvider = Provider((ref) => TransactionsRepository());

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repository = ref.read(transactionsRepositoryProvider);
  return TransactionsNotifier(repository);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final TransactionsRepository _repository;

  TransactionsNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> fetchTransactions() async {
    try {
      state = const AsyncValue.loading();
      final transactions = await _repository.getTransactions();
      state = AsyncValue.data(List<dynamic>.from(transactions));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }
}