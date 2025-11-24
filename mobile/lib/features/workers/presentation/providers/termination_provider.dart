import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/termination_model.dart';

// Stub provider for termination history
final terminationHistoryProvider = FutureProvider<List<Termination>>((ref) async {
  // TODO: Fetch from API
  return [];
});
