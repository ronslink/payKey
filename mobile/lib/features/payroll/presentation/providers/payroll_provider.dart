import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_model.dart';
import '../../data/repositories/payroll_repository.dart';
import '../../../payments/data/models/payment_model.dart';

final payrollProvider =
    StateNotifierProvider<PayrollNotifier, AsyncValue<List<PayrollCalculation>>>((ref) {
  return PayrollNotifier(ref.read(payrollRepositoryProvider));
});

final selectedWorkersProvider = StateProvider<Set<String>>((ref) => {});

class PayrollNotifier extends StateNotifier<AsyncValue<List<PayrollCalculation>>> {
  final PayrollRepository _repository;

  PayrollNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> calculatePayroll(
    List<String> workerIds, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final calculations = await _repository.calculatePayroll(
        workerIds,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(calculations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> processPayroll(
    List<String> workerIds,
    String payPeriodId,
  ) async {
    try {
      return await _repository.processPayroll(workerIds, payPeriodId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveDraftPayroll(String payPeriodId) async {
    final currentState = state.value;
    if (currentState == null || currentState.isEmpty) return;

    try {
      final items = currentState.map((c) => {
        'workerId': c.workerId,
        'grossSalary': c.grossSalary,
        'bonuses': c.bonuses,
        'otherEarnings': c.otherEarnings,
        'otherDeductions': c.otherDeductions,
      }).toList();

      final savedCalculations = await _repository.saveDraftPayroll(payPeriodId, items);
      state = AsyncValue.data(savedCalculations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWorkerPayroll({
    required String workerId,
    required double grossSalary,
    double bonuses = 0,
    double otherEarnings = 0,
    double otherDeductions = 0,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Find the calculation to get the record ID
    final calculation = currentState.firstWhere(
      (c) => c.workerId == workerId,
      orElse: () => throw Exception('Worker payroll not found'),
    );

    if (calculation.id == null) {
      // If no ID, we might need to save first or handle error.
      // Assuming saveDraftPayroll was called and state updated with IDs.
      return;
    }

    try {
      final updatedCalc = await _repository.updatePayrollItem(
        calculation.id!,
        {
          'grossSalary': grossSalary,
          'bonuses': bonuses,
          'otherEarnings': otherEarnings,
          'otherDeductions': otherDeductions,
        },
      );

      // Update state
      final newList = List<PayrollCalculation>.from(currentState);
      final index = newList.indexWhere((c) => c.workerId == workerId);
      if (index != -1) {
        newList[index] = updatedCalc;
        state = AsyncValue.data(newList);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> getDraftPayroll(String payPeriodId) async {
    state = const AsyncValue.loading();
    try {
      final calculations = await _repository.getDraftPayroll(payPeriodId);
      state = AsyncValue.data(calculations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> finalizePayroll(String payPeriodId) async {
    try {
      await _repository.finalizePayroll(payPeriodId);
      // Optionally refresh state or navigate away
    } catch (e) {
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}
