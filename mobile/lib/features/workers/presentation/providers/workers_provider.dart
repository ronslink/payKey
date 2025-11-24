import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/worker_model.dart';
import '../../data/repositories/workers_repository.dart';

final workersRepositoryProvider = Provider((ref) => WorkersRepository());

final workersProvider = StateNotifierProvider<WorkersNotifier, AsyncValue<List<WorkerModel>>>((ref) {
  return WorkersNotifier(
    ref.read(workersRepositoryProvider),
  );
});

class WorkersNotifier extends StateNotifier<AsyncValue<List<WorkerModel>>> {
  final WorkersRepository _repository;

  WorkersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadWorkers();
  }

  Future<void> loadWorkers() async {
    state = const AsyncValue.loading();
    try {
      final workers = await _repository.getWorkers();
      state = AsyncValue.data(workers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Alias for fetchWorkers to maintain compatibility
  Future<void> fetchWorkers() async {
    return loadWorkers();
  }

  Future<void> createWorker(CreateWorkerRequest request) async {
    state = const AsyncValue.loading();
    try {
      final newWorker = await _repository.createWorker(request);
      final currentState = state.value ?? [];
      state = AsyncValue.data([...currentState, newWorker]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> updateWorker(String workerId, UpdateWorkerRequest request) async {
    state = const AsyncValue.loading();
    try {
      final updatedWorker = await _repository.updateWorker(workerId, request);
      final currentState = state.value ?? [];
      final updatedList = currentState.map((worker) {
        return worker.id == workerId ? updatedWorker : worker;
      }).toList();
      state = AsyncValue.data(updatedList);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> deleteWorker(String workerId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteWorker(workerId);
      final currentState = state.value ?? [];
      final updatedList = currentState.where((worker) => worker.id != workerId).toList();
      state = AsyncValue.data(updatedList);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<int> getWorkerCount() async {
    try {
      return await _repository.getWorkerCount();
    } catch (error) {
      rethrow;
    }
  }
}
