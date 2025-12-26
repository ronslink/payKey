import 'package:flutter/material.dart';
import '../../../workers/data/models/worker_model.dart';
import '../constants/payroll_constants.dart';

/// Manages TextEditingControllers for worker payroll inputs
/// Handles lifecycle and prevents memory leaks
class WorkerHoursControllerManager {
  final Map<String, TextEditingController> _hoursControllers = {};
  final Map<String, TextEditingController> _overtimeControllers = {};
  final Map<String, TextEditingController> _bonusesControllers = {};
  final Map<String, TextEditingController> _deductionsControllers = {};
  final Map<String, TextEditingController> _daysWorkedControllers = {};
  final Map<String, bool> _isPartialPeriod = {};

  /// Get or create hours controller for a worker
  TextEditingController getHoursController(String workerId, {bool isHourly = false}) {
    return _hoursControllers.putIfAbsent(
      workerId,
      () => TextEditingController(
        text: isHourly 
            ? PayrollConstants.defaultOvertimeHours.toStringAsFixed(0)
            : PayrollConstants.defaultMonthlyHours.toStringAsFixed(0),
      ),
    );
  }

  /// Get or create overtime controller for a worker
  TextEditingController getOvertimeController(String workerId) {
    return _overtimeControllers.putIfAbsent(
      workerId,
      () => TextEditingController(
        text: PayrollConstants.defaultOvertimeHours.toStringAsFixed(0),
      ),
    );
  }

  /// Get or create bonuses controller
  TextEditingController getBonusesController(String workerId) {
    return _bonusesControllers.putIfAbsent(
      workerId,
      () => TextEditingController(text: '0'),
    );
  }

  /// Get or create deductions controller
  TextEditingController getDeductionsController(String workerId) {
    return _deductionsControllers.putIfAbsent(
      workerId,
      () => TextEditingController(text: '0'),
    );
  }

  /// Get or create days worked controller for a worker
  /// Calculates smart default based on worker status and pay period
  TextEditingController getDaysWorkedController(
    String workerId, {
    required WorkerModel worker,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return _daysWorkedControllers.putIfAbsent(workerId, () {
      final defaultDays = _calculateDefaultDays(
        worker: worker,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      
      // Track if this is a partial period
      final totalDays = periodEnd.difference(periodStart).inDays + 1;
      _isPartialPeriod[workerId] = defaultDays < totalDays;
      
      return TextEditingController(text: defaultDays.toString());
    });
  }

  /// Calculate default days worked based on worker status
  int _calculateDefaultDays({
    required WorkerModel worker,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final totalDays = periodEnd.difference(periodStart).inDays + 1;
    
    DateTime effectiveStart = periodStart;
    DateTime effectiveEnd = periodEnd;
    
    // Adjust for new hire (started after period start)
    if (worker.startDate != null && worker.startDate!.isAfter(periodStart)) {
      effectiveStart = worker.startDate!;
    }
    
    // Adjust for termination (terminated before period end)
    if (worker.terminatedAt != null && worker.terminatedAt!.isBefore(periodEnd)) {
      effectiveEnd = worker.terminatedAt!;
    }
    
    // If terminated before period started, return 0
    if (worker.terminatedAt != null && worker.terminatedAt!.isBefore(periodStart)) {
      return 0;
    }
    
    // If started after period ended, return 0
    if (worker.startDate != null && worker.startDate!.isAfter(periodEnd)) {
      return 0;
    }
    
    // Calculate actual days worked
    final daysWorked = effectiveEnd.difference(effectiveStart).inDays + 1;
    return daysWorked.clamp(0, totalDays);
  }

  /// Check if worker has partial period
  bool isPartialPeriod(String workerId) {
    return _isPartialPeriod[workerId] ?? false;
  }

  /// Get hours value for a worker
  double getHours(String workerId) {
    final controller = _hoursControllers[workerId];
    if (controller == null) return PayrollConstants.defaultMonthlyHours;
    return double.tryParse(controller.text) ?? PayrollConstants.defaultMonthlyHours;
  }

  /// Get overtime value for a worker
  double getOvertime(String workerId) {
    final controller = _overtimeControllers[workerId];
    if (controller == null) return PayrollConstants.defaultOvertimeHours;
    return double.tryParse(controller.text) ?? PayrollConstants.defaultOvertimeHours;
  }

  /// Get bonuses value for a worker
  double getBonuses(String workerId) {
    final controller = _bonusesControllers[workerId];
    if (controller == null) return 0;
    return double.tryParse(controller.text) ?? 0;
  }

  /// Get deductions value for a worker
  double getDeductions(String workerId) {
    final controller = _deductionsControllers[workerId];
    if (controller == null) return 0;
    return double.tryParse(controller.text) ?? 0;
  }

  /// Get days worked value for a worker
  int getDaysWorked(String workerId) {
    final controller = _daysWorkedControllers[workerId];
    if (controller == null) return 0;
    return int.tryParse(controller.text) ?? 0;
  }

  /// Remove controllers for workers no longer in the list
  void syncWithWorkers(List<String> currentWorkerIds) {
    final idsToRemove = _hoursControllers.keys
        .where((id) => !currentWorkerIds.contains(id))
        .toList();

    for (final id in idsToRemove) {
      _hoursControllers[id]?.dispose();
      _hoursControllers.remove(id);
      _overtimeControllers[id]?.dispose();
      _overtimeControllers.remove(id);
      _bonusesControllers[id]?.dispose();
      _bonusesControllers.remove(id);
      _deductionsControllers[id]?.dispose();
      _deductionsControllers.remove(id);
      _daysWorkedControllers[id]?.dispose();
      _daysWorkedControllers.remove(id);
      _isPartialPeriod.remove(id);
    }
  }

  /// Dispose all controllers
  void dispose() {
    for (final controller in _hoursControllers.values) {
      controller.dispose();
    }
    for (final controller in _overtimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _bonusesControllers.values) {
      controller.dispose();
    }
    for (final controller in _deductionsControllers.values) {
      controller.dispose();
    }
    for (final controller in _daysWorkedControllers.values) {
      controller.dispose();
    }
    _hoursControllers.clear();
    _overtimeControllers.clear();
    _bonusesControllers.clear();
    _deductionsControllers.clear();
    _daysWorkedControllers.clear();
    _isPartialPeriod.clear();
  }
}
