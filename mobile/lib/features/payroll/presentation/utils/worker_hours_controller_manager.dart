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
  
  /// Attendance hours from time tracking, indexed by workerId
  /// These override defaults when available (for hourly workers)
  Map<String, double> _attendanceHours = {};
  
  /// Attendance overtime hours (excess beyond standard threshold)
  Map<String, double> _attendanceOvertimeHours = {};

  /// Set attendance data from time tracking summary
  /// Call this after fetching attendance summary to pre-populate hours
  /// Hours exceeding the standard threshold are automatically split into overtime
  void setAttendanceData(Map<String, double> attendanceHours) {
    final standardHours = _getDefaultHoursForPeriod();
    
    // Clear previous overtime data
    _attendanceOvertimeHours.clear();
    
    // Split hours into regular and overtime
    final regularHours = <String, double>{};
    for (final entry in attendanceHours.entries) {
      if (entry.value > standardHours) {
        // Hours exceed threshold - split into regular and overtime
        regularHours[entry.key] = standardHours;
        _attendanceOvertimeHours[entry.key] = entry.value - standardHours;
      } else {
        regularHours[entry.key] = entry.value;
      }
    }
    
    _attendanceHours = regularHours;
    
    // Update existing controllers with attendance data
    for (final entry in regularHours.entries) {
      if (_hoursControllers.containsKey(entry.key)) {
        _hoursControllers[entry.key]!.text = entry.value.toStringAsFixed(1);
      }
    }
    
    // Update overtime controllers
    for (final entry in _attendanceOvertimeHours.entries) {
      if (_overtimeControllers.containsKey(entry.key)) {
        _overtimeControllers[entry.key]!.text = entry.value.toStringAsFixed(1);
      }
    }
  }
  
  /// Clear attendance data (e.g., when period changes)
  void clearAttendanceData() {
    _attendanceHours.clear();
    _attendanceOvertimeHours.clear();
  }

  /// Pay period days - used to calculate default hours for hourly workers
  int _payPeriodDays = 30; // Default to monthly
  
  /// Set the current pay period duration in days
  /// This is used to calculate appropriate default hours:
  /// - Weekly (7 days) → 40 hours
  /// - Bi-weekly (14 days) → 80 hours  
  /// - Monthly (28-31 days) → 160 hours
  void setPayPeriodDays(int days) {
    _payPeriodDays = days;
  }
  
  /// Calculate default hours based on pay period duration
  double _getDefaultHoursForPeriod() {
    if (_payPeriodDays <= 7) {
      return 40.0; // Weekly
    } else if (_payPeriodDays <= 14) {
      return 80.0; // Bi-weekly
    } else {
      return PayrollConstants.defaultMonthlyHours; // Monthly (160)
    }
  }

  /// Get or create hours controller for a worker
  /// For hourly workers, uses attendance hours from time tracking if available,
  /// otherwise uses pay period-based defaults (weekly=40h, bi-weekly=80h, monthly=160h)
  TextEditingController getHoursController(String workerId, {bool isHourly = false}) {
    return _hoursControllers.putIfAbsent(
      workerId,
      () {
        // For hourly workers, check if we have attendance data from time tracking
        if (isHourly && _attendanceHours.containsKey(workerId)) {
          final trackedHours = _attendanceHours[workerId]!;
          return TextEditingController(
            text: trackedHours.toStringAsFixed(1),
          );
        }
        
        // Use period-based default hours
        final defaultHours = _getDefaultHoursForPeriod();
        return TextEditingController(
          text: defaultHours.toStringAsFixed(0),
        );
      },
    );
  }

  /// Get or create overtime controller for a worker
  /// Uses attendance overtime data (hours exceeding threshold) if available
  TextEditingController getOvertimeController(String workerId) {
    return _overtimeControllers.putIfAbsent(
      workerId,
      () {
        // Check if we have overtime from attendance data (hours that exceeded threshold)
        if (_attendanceOvertimeHours.containsKey(workerId)) {
          final overtimeHours = _attendanceOvertimeHours[workerId]!;
          return TextEditingController(
            text: overtimeHours.toStringAsFixed(1),
          );
        }
        
        // Default to 0 overtime
        return TextEditingController(
          text: PayrollConstants.defaultOvertimeHours.toStringAsFixed(0),
        );
      },
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
    // Normalize dates to ignore time components
    final pStart_ = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final pEnd_ = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    final wStart = worker.startDate != null 
        ? DateTime(worker.startDate!.year, worker.startDate!.month, worker.startDate!.day) 
        : null;
    final wEnd = worker.terminatedAt != null 
        ? DateTime(worker.terminatedAt!.year, worker.terminatedAt!.month, worker.terminatedAt!.day) 
        : null;

    debugPrint('Calculating defaults for ${worker.name}: Period ${pStart_} - ${pEnd_}, Worker Start: ${wStart}, End: ${wEnd}');

    final totalDays = pEnd_.difference(pStart_).inDays + 1;
    
    DateTime effectiveStart = pStart_;
    DateTime effectiveEnd = pEnd_;
    
    // Adjust for new hire (started after period start)
    if (wStart != null && wStart.isAfter(pStart_)) {
      effectiveStart = wStart;
    }
    
    // Adjust for termination (terminated before period end)
    if (wEnd != null && wEnd.isBefore(pEnd_)) {
      effectiveEnd = wEnd;
    }
    
    // If terminated before period started, return 0
    if (wEnd != null && wEnd.isBefore(pStart_)) {
      return 0;
    }
    
    // If started after period ended, return 0
    if (wStart != null && wStart.isAfter(pEnd_)) {
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

  /// Clear all days worked controllers to force recalculation
  /// Use when pay period changes
  void clearDaysWorkedControllers() {
    for (final controller in _daysWorkedControllers.values) {
      controller.dispose();
    }
    _daysWorkedControllers.clear();
    _isPartialPeriod.clear();
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
