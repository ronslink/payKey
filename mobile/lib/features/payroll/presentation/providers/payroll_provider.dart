import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/download_utils.dart';
import '../../data/models/payroll_model.dart';
import '../../data/repositories/payroll_repository.dart';

final payrollProvider =
    AsyncNotifierProvider<PayrollNotifier, List<PayrollCalculation>>(PayrollNotifier.new);

final selectedWorkersProvider = NotifierProvider<SelectedWorkersNotifier, Set<String>>(SelectedWorkersNotifier.new);

class SelectedWorkersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }
  
  void clear() => state = {};
  
  void set(Set<String> ids) => state = ids;
}

class PayrollNotifier extends AsyncNotifier<List<PayrollCalculation>> {
  late PayrollRepository _repository;

  @override
  FutureOr<List<PayrollCalculation>> build() {
    _repository = ref.watch(payrollRepositoryProvider);
    return []; // Initial empty state
    // Or if we want to load existing drafts etc automatically:
    // return _repository.getDraftPayroll(currentPeriodId); 
    // But usage seems to call specific methods.
  }

  Future<void> calculatePayroll(
    List<String> workerIds, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.calculatePayroll(
        workerIds,
        startDate: startDate,
        endDate: endDate,
      ));
  }

  Future<PayrollProcessingResult> processPayroll(
    List<String> workerIds,
    String payPeriodId, {
    bool skipPayout = false,
  }) async {
    try {
      return await _repository.processPayroll(
        workerIds,
        payPeriodId,
        skipPayout: skipPayout,
      );
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
    state = await AsyncValue.guard(() => _repository.getDraftPayroll(payPeriodId));
  }

  Future<void> finalizePayroll(String payPeriodId) async {
    try {
      await _repository.finalizePayroll(payPeriodId);
      // Optionally refresh state or navigate away
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recalculatePayroll(String payPeriodId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.recalculatePayroll(payPeriodId));
  }

  Future<void> downloadPayslip(String payrollRecordId, String workerName) async {
    try {
      final bytes = await _repository.downloadPayslip(payrollRecordId);
      
      await DownloadUtils.downloadFile(
        filename: 'payslip_${workerName.replaceAll(' ', '_')}.pdf',
        bytes: bytes,
      );
    } catch (e) {
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}
