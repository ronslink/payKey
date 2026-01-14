import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/worker_model.dart';
import '../../data/repositories/workers_repository.dart';

final workersRepositoryProvider = Provider((ref) => WorkersRepository(ApiService()));

final workersProvider = AsyncNotifierProvider<WorkersNotifier, List<WorkerModel>>(WorkersNotifier.new);

class WorkersNotifier extends AsyncNotifier<List<WorkerModel>> {
  late WorkersRepository _repository;

  @override
  FutureOr<List<WorkerModel>> build() {
    _repository = ref.watch(workersRepositoryProvider);
    return _loadWorkers();
  }

  Future<List<WorkerModel>> _loadWorkers() {
    return _repository.getWorkers();
  }

  // Alias for fetchWorkers to maintain compatibility
  Future<void> fetchWorkers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadWorkers());
  }

  // Alias for backward compatibility
  Future<void> loadWorkers() => fetchWorkers();

  Future<void> createWorker(CreateWorkerRequest request) async {
    final prevState = state.value;
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final newWorker = await _repository.createWorker(request);
      return [...?prevState, newWorker];
    });
  }

  Future<void> updateWorker(String workerId, UpdateWorkerRequest request) async {
    final prevState = state.value;
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final updatedWorker = await _repository.updateWorker(workerId, request);
      return [
        for (final worker in prevState ?? [])
          if (worker.id == workerId) updatedWorker else worker
      ];
    });
  }

  Future<void> deleteWorker(String workerId) async {
    final prevState = state.value;
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await _repository.deleteWorker(workerId);
      return [
        for (final worker in prevState ?? [])
          if (worker.id != workerId) worker
      ];
    });
  }

  Future<void> uploadPhoto(String workerId, List<int> bytes, String filename) async {
    final prevState = state.value;
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final updatedWorker = await _repository.uploadWorkerPhoto(workerId, bytes, filename);
      return [
        for (final worker in prevState ?? [])
          if (worker.id == workerId) updatedWorker else worker
      ];
    });
  }

  Future<int> getWorkerCount() async {
    return _repository.getWorkerCount();
  }
}
