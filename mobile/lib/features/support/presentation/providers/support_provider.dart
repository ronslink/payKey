import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/support_ticket.dart';
import '../../data/repositories/support_repository.dart';

final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.getTickets();
});

final currentTicketProvider = FutureProvider.family.autoDispose<SupportTicket, String>((ref, id) async {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.getTicket(id);
});

class SupportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTicket(String subject, String description, TicketCategory category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(supportRepositoryProvider);
      await repository.createTicket(subject, description, category);
      ref.invalidate(supportTicketsProvider);
    });
  }

  Future<void> addReply(String ticketId, String message) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(supportRepositoryProvider);
      await repository.addReply(ticketId, message);
      ref.invalidate(currentTicketProvider(ticketId));
    });
  }
}

final supportNotifierProvider = AsyncNotifierProvider<SupportNotifier, void>(SupportNotifier.new);
