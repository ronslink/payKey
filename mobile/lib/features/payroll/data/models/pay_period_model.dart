// ignore_for_file: invalid_annotation_target
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pay_period_model.freezed.dart';
part 'pay_period_model.g.dart';

// =============================================================================
// ENUMS
// =============================================================================

/// How often pay periods occur.
enum PayPeriodFrequency {
  @JsonValue('WEEKLY')
  weekly,
  @JsonValue('BIWEEKLY')
  biWeekly,
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('QUARTERLY')
  quarterly,
  @JsonValue('YEARLY')
  yearly;

  /// Create PayPeriodFrequency from string (handles both uppercase and lowercase)
  static PayPeriodFrequency fromString(String value) {
    switch (value.toUpperCase()) {
      case 'WEEKLY':
        return weekly;
      case 'BIWEEKLY':
        return biWeekly;
      case 'MONTHLY':
        return monthly;
      case 'QUARTERLY':
        return quarterly;
      case 'YEARLY':
        return yearly;
      default:
        throw ArgumentError('Invalid frequency value: $value. Supported values: WEEKLY, BIWEEKLY, MONTHLY, QUARTERLY, YEARLY');
    }
  }

  /// Human-readable display label.
  String get displayName {
    return switch (this) {
      PayPeriodFrequency.weekly => 'Weekly',
      PayPeriodFrequency.biWeekly => 'Bi-Weekly',
      PayPeriodFrequency.monthly => 'Monthly',
      PayPeriodFrequency.quarterly => 'Quarterly',
      PayPeriodFrequency.yearly => 'Yearly',
    };
  }

  /// Approximate number of days in this frequency.
  int get approximateDays {
    return switch (this) {
      PayPeriodFrequency.weekly => 7,
      PayPeriodFrequency.biWeekly => 14,
      PayPeriodFrequency.monthly => 30,
      PayPeriodFrequency.quarterly => 90,
      PayPeriodFrequency.yearly => 365,
    };
  }

  /// Number of periods per year.
  int get periodsPerYear {
    return switch (this) {
      PayPeriodFrequency.weekly => 52,
      PayPeriodFrequency.biWeekly => 26,
      PayPeriodFrequency.monthly => 12,
      PayPeriodFrequency.quarterly => 4,
      PayPeriodFrequency.yearly => 1,
    };
  }
}

/// Status of a pay period in the payroll workflow.
///
/// Lifecycle: DRAFT -> ACTIVE -> PROCESSING -> COMPLETED -> CLOSED
enum PayPeriodStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CLOSED')
  closed,
  @JsonValue('CANCELLED')
  cancelled;

  /// Human-readable display label.
  String get displayName {
    return switch (this) {
      PayPeriodStatus.draft => 'Draft',
      PayPeriodStatus.active => 'Active',
      PayPeriodStatus.processing => 'Processing',
      PayPeriodStatus.completed => 'Completed',
      PayPeriodStatus.closed => 'Closed',
      PayPeriodStatus.cancelled => 'Cancelled',
    };
  }

  /// Color hint for UI (returns color name or hex suggestion).
  String get colorHint {
    return switch (this) {
      PayPeriodStatus.draft => 'grey',
      PayPeriodStatus.active => 'blue',
      PayPeriodStatus.processing => 'orange',
      PayPeriodStatus.completed => 'green',
      PayPeriodStatus.closed => 'purple',
      PayPeriodStatus.cancelled => 'red',
    };
  }

  /// Whether this status allows editing.
  bool get isEditable => this == draft || this == active;

  /// Whether this is a terminal state.
  bool get isTerminal => this == closed || this == cancelled;

  /// Whether payroll can be processed in this status.
  bool get canProcess => this == active;

  /// Whether payments can be initiated in this status.
  bool get canInitiatePayments => this == completed;
}

/// Actions that can be performed on a pay period to change its status.
enum PayPeriodStatusAction {
  activate,
  process,
  complete,
  close,
  cancel,
  reopen;

  /// Human-readable display label.
  String get displayName {
    return switch (this) {
      PayPeriodStatusAction.activate => 'Activate',
      PayPeriodStatusAction.process => 'Process',
      PayPeriodStatusAction.complete => 'Complete',
      PayPeriodStatusAction.close => 'Close',
      PayPeriodStatusAction.cancel => 'Cancel',
      PayPeriodStatusAction.reopen => 'Reopen',
    };
  }

  /// The resulting status after this action.
  PayPeriodStatus get resultingStatus {
    return switch (this) {
      PayPeriodStatusAction.activate => PayPeriodStatus.active,
      PayPeriodStatusAction.process => PayPeriodStatus.processing,
      PayPeriodStatusAction.complete => PayPeriodStatus.completed,
      PayPeriodStatusAction.close => PayPeriodStatus.closed,
      PayPeriodStatusAction.cancel => PayPeriodStatus.cancelled,
      PayPeriodStatusAction.reopen => PayPeriodStatus.draft,
    };
  }
}

// =============================================================================
// STATUS TRANSITIONS
// =============================================================================

/// Valid status transitions for pay periods.
const Map<PayPeriodStatus, List<PayPeriodStatus>> payPeriodTransitions = {
  PayPeriodStatus.draft: [PayPeriodStatus.active, PayPeriodStatus.cancelled],
  PayPeriodStatus.active: [
    PayPeriodStatus.processing,
    PayPeriodStatus.draft,
    PayPeriodStatus.cancelled
  ],
  PayPeriodStatus.processing: [
    PayPeriodStatus.completed,
    PayPeriodStatus.active
  ],
  PayPeriodStatus.completed: [
    PayPeriodStatus.closed,
    PayPeriodStatus.processing
  ],
  PayPeriodStatus.closed: [], // Terminal state
  PayPeriodStatus.cancelled: [PayPeriodStatus.draft], // Can reopen
};

/// Valid actions for each status.
const Map<PayPeriodStatus, List<PayPeriodStatusAction>> payPeriodActions = {
  PayPeriodStatus.draft: [
    PayPeriodStatusAction.activate,
    PayPeriodStatusAction.cancel
  ],
  PayPeriodStatus.active: [
    PayPeriodStatusAction.process,
    PayPeriodStatusAction.cancel
  ],
  PayPeriodStatus.processing: [PayPeriodStatusAction.complete],
  PayPeriodStatus.completed: [PayPeriodStatusAction.close],
  PayPeriodStatus.closed: [],
  PayPeriodStatus.cancelled: [PayPeriodStatusAction.reopen],
};

// =============================================================================
// PAY PERIOD MODEL
// =============================================================================

/// Represents a pay period for payroll processing.
///
/// A pay period defines a date range for which workers are paid,
/// tracks processing status, and aggregates financial totals.
@freezed
abstract class PayPeriod with _$PayPeriod {
  const PayPeriod._();

  const factory PayPeriod({
    /// Unique identifier.
    required String id,

    /// Display name (e.g., "August 2025", "Week 32").
    required String name,

    /// First day of the pay period (inclusive).
    required DateTime startDate,

    /// Last day of the pay period (inclusive).
    required DateTime endDate,

    /// How often this type of period recurs.
    required PayPeriodFrequency frequency,

    /// Current status in the payroll workflow.
    required PayPeriodStatus status,

    /// Total number of workers included in this period.
    @JsonKey(fromJson: _intFromJson)
    int? totalWorkers,

    /// Sum of all gross salaries.
    @JsonKey(fromJson: _doubleFromJson)
    double? totalGrossAmount,

    /// Sum of all net pay amounts.
    @JsonKey(fromJson: _doubleFromJson)
    double? totalNetAmount,

    /// Sum of all tax deductions.
    @JsonKey(fromJson: _doubleFromJson)
    double? totalTaxAmount,

    /// Number of workers whose payroll has been processed.
    @JsonKey(fromJson: _intFromJson)
    int? processedWorkers,

    /// When this pay period was created.
    DateTime? createdAt,

    /// When this pay period was last updated.
    DateTime? updatedAt,

    /// Additional notes or comments.
    String? notes,

    /// Owner/employer user ID.
    String? userId,

    /// Scheduled payment date.
    DateTime? payDate,
  }) = _PayPeriod;

  factory PayPeriod.fromJson(Map<String, dynamic> json) =>
      _$PayPeriodFromJson(json);

  // ---------------------------------------------------------------------------
  // Computed Properties: Status
  // ---------------------------------------------------------------------------

  /// Whether this pay period can be edited.
  bool get isEditable => status.isEditable;

  /// Whether this pay period is in a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Whether payroll can be processed.
  bool get canProcess => status.canProcess;

  /// Whether payments can be initiated.
  bool get canInitiatePayments => status.canInitiatePayments;

  /// Valid status transitions from current state.
  List<PayPeriodStatus> get validTransitions =>
      payPeriodTransitions[status] ?? [];

  /// Valid actions from current state.
  List<PayPeriodStatusAction> get validActions =>
      payPeriodActions[status] ?? [];

  /// Check if a specific transition is valid.
  bool canTransitionTo(PayPeriodStatus newStatus) =>
      validTransitions.contains(newStatus);

  // ---------------------------------------------------------------------------
  // Computed Properties: Progress
  // ---------------------------------------------------------------------------

  /// Number of workers pending processing.
  int get pendingWorkers {
    final total = totalWorkers ?? 0;
    final processed = processedWorkers ?? 0;
    return (total - processed).clamp(0, total);
  }

  /// Processing completion percentage (0-100).
  double get completionPercentage {
    final total = totalWorkers ?? 0;
    if (total == 0) return 0;
    return ((processedWorkers ?? 0) / total * 100).clamp(0, 100);
  }

  /// Whether all workers have been processed.
  bool get isFullyProcessed {
    final total = totalWorkers ?? 0;
    return total > 0 && (processedWorkers ?? 0) >= total;
  }

  // ---------------------------------------------------------------------------
  // Computed Properties: Financials
  // ---------------------------------------------------------------------------

  /// Total deductions (gross minus net).
  double get totalDeductions {
    final gross = totalGrossAmount ?? 0;
    final net = totalNetAmount ?? 0;
    return (gross - net).clamp(0, double.infinity);
  }

  /// Effective tax rate as a percentage.
  double get effectiveTaxRate {
    final gross = totalGrossAmount ?? 0;
    if (gross == 0) return 0;
    return ((totalTaxAmount ?? 0) / gross * 100).clamp(0, 100);
  }

  /// Average gross salary per worker.
  double get averageGrossSalary {
    final total = totalWorkers ?? 0;
    if (total == 0) return 0;
    return (totalGrossAmount ?? 0) / total;
  }

  /// Average net pay per worker.
  double get averageNetPay {
    final total = totalWorkers ?? 0;
    if (total == 0) return 0;
    return (totalNetAmount ?? 0) / total;
  }

  // ---------------------------------------------------------------------------
  // Computed Properties: Dates
  // ---------------------------------------------------------------------------

  /// Number of days in this pay period.
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Whether the pay period is currently active (date-wise).
  bool get isCurrentPeriod {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  /// Whether the pay period end date has passed.
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return today.isAfter(end);
  }

  /// Whether the pay period hasn't started yet.
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return today.isBefore(start);
  }

  /// Days until pay date (negative if past).
  int? get daysUntilPayDate {
    if (payDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pay = DateTime(payDate!.year, payDate!.month, payDate!.day);
    return pay.difference(today).inDays;
  }

  // ---------------------------------------------------------------------------
  // Methods: Validation
  // ---------------------------------------------------------------------------

  /// Check if a date falls within this pay period.
  bool containsDate(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !checkDate.isBefore(start) && !checkDate.isAfter(end);
  }

  /// Validate the pay period data.
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Name is required');
    }

    if (endDate.isBefore(startDate)) {
      errors.add('End date cannot be before start date');
    }

    if (durationDays > 366) {
      errors.add('Pay period cannot exceed one year');
    }

    if ((totalWorkers ?? 0) < 0) {
      errors.add('Total workers cannot be negative');
    }

    if ((processedWorkers ?? 0) > (totalWorkers ?? 0)) {
      errors.add('Processed workers cannot exceed total workers');
    }

    return errors;
  }

  /// Whether the pay period data is valid.
  bool get isValid => validate().isEmpty;
}

// =============================================================================
// REQUEST MODELS
// =============================================================================

/// Request payload for creating a new pay period.
@freezed
abstract class CreatePayPeriodRequest with _$CreatePayPeriodRequest {
  const CreatePayPeriodRequest._();

  const factory CreatePayPeriodRequest({
    /// Display name for the pay period.
    required String name,

    /// First day of the pay period.
    required DateTime startDate,

    /// Last day of the pay period.
    required DateTime endDate,

    /// Pay frequency.
    required PayPeriodFrequency frequency,

    /// Optional notes.
    String? notes,

    /// Whether this is an off-cycle payroll (bonus, advance, etc.).
    @Default(false) bool isOffCycle,
  }) = _CreatePayPeriodRequest;

  factory CreatePayPeriodRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePayPeriodRequestFromJson(json);

  /// Create a monthly pay period for a given month.
  factory CreatePayPeriodRequest.forMonth(int year, int month, {String? notes}) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    final monthName = _monthNames[month - 1];
    final name = '$monthName $year';

    return CreatePayPeriodRequest(
      name: name,
      startDate: startDate,
      endDate: endDate,
      frequency: PayPeriodFrequency.monthly,
      notes: notes,
    );
  }

  /// Create a weekly pay period starting from a given date.
  factory CreatePayPeriodRequest.forWeek(DateTime startDate, {String? notes}) {
    final endDate = startDate.add(const Duration(days: 6));
    final weekNumber = _weekNumber(startDate);
    final name = 'Week $weekNumber, ${startDate.year}';

    return CreatePayPeriodRequest(
      name: name,
      startDate: startDate,
      endDate: endDate,
      frequency: PayPeriodFrequency.weekly,
      notes: notes,
    );
  }

  /// Validate the request data.
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Name is required');
    }

    if (endDate.isBefore(startDate)) {
      errors.add('End date cannot be before start date');
    }

    return errors;
  }

  /// Whether the request data is valid.
  bool get isValid => validate().isEmpty;
}

/// Request payload for updating an existing pay period.
@freezed
abstract class UpdatePayPeriodRequest with _$UpdatePayPeriodRequest {
  const UpdatePayPeriodRequest._();

  const factory UpdatePayPeriodRequest({
    /// Updated name (optional).
    String? name,

    /// Updated start date (optional).
    DateTime? startDate,

    /// Updated end date (optional).
    DateTime? endDate,

    /// Updated frequency (optional).
    PayPeriodFrequency? frequency,

    /// Updated status (optional).
    PayPeriodStatus? status,

    /// Updated notes (optional).
    String? notes,
  }) = _UpdatePayPeriodRequest;

  factory UpdatePayPeriodRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePayPeriodRequestFromJson(json);

  /// Whether any field is set for update.
  bool get hasChanges =>
      name != null ||
      startDate != null ||
      endDate != null ||
      frequency != null ||
      status != null ||
      notes != null;

  /// Create an update request to change only the status.
  factory UpdatePayPeriodRequest.statusOnly(PayPeriodStatus status) {
    return UpdatePayPeriodRequest(status: status);
  }

  /// Create an update request to change only the notes.
  factory UpdatePayPeriodRequest.notesOnly(String notes) {
    return UpdatePayPeriodRequest(notes: notes);
  }

  /// Create an update request to change the date range.
  factory UpdatePayPeriodRequest.dateRange(DateTime start, DateTime end) {
    return UpdatePayPeriodRequest(startDate: start, endDate: end);
  }
}

// =============================================================================
// JSON CONVERTERS
// =============================================================================

/// Convert dynamic value to int (handles String and double).
int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Convert dynamic value to double (handles String and int).
double? _doubleFromJson(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Pass-through converter for toJson.
// Note: This function is currently unused but kept for future reference
// dynamic _valueToJson(dynamic value) => value;

// =============================================================================
// HELPERS
// =============================================================================

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

int _weekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final dayOfYear = date.difference(firstDayOfYear).inDays;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension methods for PayPeriodStatus providing UI-related properties.
extension PayPeriodStatusExtension on PayPeriodStatus {
  /// Get the color for this status.
  Color get color {
    switch (this) {
      case PayPeriodStatus.draft:
        return Colors.grey.shade600;
      case PayPeriodStatus.active:
        return Colors.blue;
      case PayPeriodStatus.processing:
        return Colors.orange;
      case PayPeriodStatus.completed:
        return Colors.green;
      case PayPeriodStatus.closed:
        return Colors.deepPurple;
      case PayPeriodStatus.cancelled:
        return Colors.red;
    }
  }

  /// Get the available actions for this status.
  List<PayPeriodStatusAction> get availableActions {
    switch (this) {
      case PayPeriodStatus.draft:
        return [PayPeriodStatusAction.activate, PayPeriodStatusAction.close];
      case PayPeriodStatus.active:
        return [PayPeriodStatusAction.process, PayPeriodStatusAction.close];
      case PayPeriodStatus.processing:
        return [PayPeriodStatusAction.complete, PayPeriodStatusAction.close];
      case PayPeriodStatus.completed:
        return [PayPeriodStatusAction.close];
      case PayPeriodStatus.closed:
      case PayPeriodStatus.cancelled:
        return [];
    }
  }
}

/// Extension methods for PayPeriodStatusAction providing UI-related properties.
extension PayPeriodStatusActionExtension on PayPeriodStatusAction {
  /// Get the label for this action.
  String get label {
    switch (this) {
      case PayPeriodStatusAction.activate:
        return 'Activate';
      case PayPeriodStatusAction.process:
        return 'Process';
      case PayPeriodStatusAction.complete:
        return 'Complete';
      case PayPeriodStatusAction.close:
        return 'Close';
      case PayPeriodStatusAction.cancel:
        return 'Cancel';
      case PayPeriodStatusAction.reopen:
        return 'Reopen';
    }
  }

  /// Get the color for this action.
  Color get color {
    switch (this) {
      case PayPeriodStatusAction.activate:
        return Colors.blue;
      case PayPeriodStatusAction.process:
        return Colors.orange;
      case PayPeriodStatusAction.complete:
        return Colors.green;
      case PayPeriodStatusAction.close:
        return Colors.red;
      case PayPeriodStatusAction.cancel:
        return Colors.red;
      case PayPeriodStatusAction.reopen:
        return Colors.blue;
    }
  }
}

/// Extension methods for PayPeriodFrequency providing UI-related properties.
extension PayPeriodFrequencyExtension on PayPeriodFrequency {
  /// Get display name with underscores replaced by spaces.
  String get displayLabel => name.replaceAll('_', ' ');
}