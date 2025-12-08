import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/termination_model.dart';
import '../../data/repositories/termination_repository.dart';

final terminationHistoryProvider = FutureProvider<List<Termination>>((ref) async {
  final repository = ref.watch(terminationRepositoryProvider);
  return repository.getTerminationHistory();
});
