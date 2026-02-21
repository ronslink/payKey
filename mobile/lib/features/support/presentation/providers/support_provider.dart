import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/support_ticket.dart';
import '../../models/support_message.dart';
import '../data/repositories/support_repository.dart';

final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.getTickets();
});

final currentTicketProvider = FutureProvider.family.autoDispose<SupportTicket, String>((ref, id) async {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.getTicket(id);
});

class SupportNotifier extends StateNotifier<AsyncValue<void>> {
  final SupportRepository _repository;
  final Ref _ref;

  SupportNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createTicket(String subject, String description, TicketCategory category) async {
    try {
      state = const AsyncValue.loading();
      await _repository.createTicket(subject, description, category);
      _ref.invalidate(supportTicketsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addReply(String ticketId, String message) async {
    try {
      state = const AsyncValue.loading();
      await _repository.addReply(ticketId, message);
      _ref.invalidate(currentTicketProvider(ticketId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final supportNotifierProvider = StateNotifierProvider<SupportNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(supportRepositoryProvider);
  return SupportNotifier(repository, ref);
});
