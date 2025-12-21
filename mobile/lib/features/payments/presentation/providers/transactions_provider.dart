import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transactions_repository.dart';

final transactionsRepositoryProvider = Provider((ref) => TransactionsRepository());

class TransactionsNotifier extends AsyncNotifier<List<dynamic>> {
  late final TransactionsRepository _repository;

  @override
  FutureOr<List<dynamic>> build() {
    _repository = ref.watch(transactionsRepositoryProvider);
    return _fetchTransactions();
  }

  Future<List<dynamic>> _fetchTransactions() async {
    final transactions = await _repository.getTransactions();
    return List<dynamic>.from(transactions);
  }

  Future<void> fetchTransactions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<dynamic>>(TransactionsNotifier.new);