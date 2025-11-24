import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transactions_repository.dart';

final transactionsRepositoryProvider = Provider((ref) => TransactionsRepository());

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.read(transactionsRepositoryProvider);
  return PaymentsNotifier(repository);
});

class PaymentsNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionsRepository _repository;

  PaymentsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> initiatePayment(String phoneNumber, double amount) async {
    try {
      state = const AsyncValue.loading();
      // Implement payment logic
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error.toString(), stackTrace);
    }
  }
}
