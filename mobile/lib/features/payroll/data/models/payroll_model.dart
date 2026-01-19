import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_model.freezed.dart';
part 'payroll_model.g.dart';

// =============================================================================
// TAX BREAKDOWN
// =============================================================================

/// Represents the breakdown of statutory deductions for a payroll calculation.
/// 
/// All values are in KES (Kenyan Shillings).
@freezed
abstract class TaxBreakdown with _$TaxBreakdown {
  const TaxBreakdown._();

  const factory TaxBreakdown({
    /// National Social Security Fund contribution
    required double nssf,

    /// National Hospital Insurance Fund contribution
    required double nhif,

    /// Affordable Housing Levy (1.5% of gross salary)
    required double housingLevy,

    /// Pay As You Earn tax
    required double paye,

    /// Sum of all deductions (nssf + nhif + housingLevy + paye)
    required double totalDeductions,
  }) = _TaxBreakdown;

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) =>
      _$TaxBreakdownFromJson(json);

  /// Creates an empty tax breakdown with all values set to zero.
  factory TaxBreakdown.zero() => const TaxBreakdown(
        nssf: 0,
        nhif: 0,
        housingLevy: 0,
        paye: 0,
        totalDeductions: 0,
      );

  /// Returns true if all deduction values are zero.
  bool get isEmpty => totalDeductions == 0;

  /// Returns true if any deduction value is non-zero.
  bool get isNotEmpty => !isEmpty;

  /// Validates that totalDeductions equals the sum of individual deductions.
  bool get isValid {
    final calculatedTotal = nssf + nhif + housingLevy + paye;
    // Allow for small floating point differences
    return (totalDeductions - calculatedTotal).abs() < 0.01;
  }

  /// Returns a map of deduction labels to their values.
  Map<String, double> toDisplayMap() => {
        'NSSF': nssf,
        'NHIF': nhif,
        'Housing Levy': housingLevy,
        'PAYE': paye,
      };
}

// =============================================================================
// PAYROLL CALCULATION
// =============================================================================

/// Status values for a payroll calculation item.
abstract class PayrollStatus {
  static const String draft = 'draft';
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String processed = 'processed';
  static const String paid = 'paid';

  static const List<String> values = [draft, pending, approved, processed, paid];

  static bool isValid(String status) => values.contains(status);
}

/// Represents a single worker's payroll calculation for a pay period.
/// 
/// Contains gross earnings, deductions breakdown, and net pay.
@freezed
abstract class PayrollCalculation with _$PayrollCalculation {
  const PayrollCalculation._();

  const factory PayrollCalculation({
    /// Unique identifier. Null for new/unsaved calculations.
    String? id,

    /// Reference to the worker this calculation belongs to.
    required String workerId,

    /// Worker's display name (denormalized for convenience).
    required String workerName,

    /// Base salary before any additions or deductions.
    @Default(0) double grossSalary,

    /// Additional bonus payments.
    @Default(0) double bonuses,

    /// Other earnings (allowances, overtime, etc.).
    @Default(0) double otherEarnings,

    /// Additional deductions (loans, advances, etc.).
    @Default(0) double otherDeductions,

    /// Breakdown of statutory tax deductions.
    required TaxBreakdown taxBreakdown,

    /// Final amount payable to worker.
    required double netPay,

    /// Current status in the payroll workflow.
    @Default(PayrollStatus.draft) String status,

    /// Whether this calculation has been manually edited.
    @Default(false) bool isEdited,
  }) = _PayrollCalculation;

  factory PayrollCalculation.fromJson(Map<String, dynamic> json) =>
      _$PayrollCalculationFromJson(json);

  /// Returns true if this calculation has been persisted.
  bool get isSaved => id != null;

  /// Returns true if this calculation is still editable.
  bool get isEditable =>
      status == PayrollStatus.draft || status == PayrollStatus.pending;

  /// Total gross earnings including bonuses and other earnings.
  double get totalGrossEarnings => grossSalary + bonuses + otherEarnings;

  /// Total deductions including statutory and other deductions.
  double get totalDeductions => taxBreakdown.totalDeductions + otherDeductions;

  /// Validates that netPay equals totalGrossEarnings minus totalDeductions.
  bool get isValid {
    final calculatedNet = totalGrossEarnings - totalDeductions;
    // Allow for small floating point differences
    return (netPay - calculatedNet).abs() < 0.01;
  }

  /// Returns a summary map suitable for display.
  Map<String, double> toEarningsSummary() => {
        'Basic Salary': grossSalary,
        if (bonuses > 0) 'Bonuses': bonuses,
        if (otherEarnings > 0) 'Other Earnings': otherEarnings,
      };

  /// Returns a summary map of all deductions.
  Map<String, double> toDeductionsSummary() => {
        ...taxBreakdown.toDisplayMap(),
        if (otherDeductions > 0) 'Other Deductions': otherDeductions,
      };
}

// =============================================================================
// PAYROLL REQUEST
// =============================================================================

/// Request payload for calculating payroll for multiple workers.
@freezed
abstract class PayrollRequest with _$PayrollRequest {
  const PayrollRequest._();

  const factory PayrollRequest({
    /// List of worker IDs to calculate payroll for.
    required List<String> workerIds,
  }) = _PayrollRequest;

  factory PayrollRequest.fromJson(Map<String, dynamic> json) =>
      _$PayrollRequestFromJson(json);

  /// Returns true if the request contains at least one worker.
  bool get isValid => workerIds.isNotEmpty;

  /// Number of workers in this request.
  int get workerCount => workerIds.length;
}

// =============================================================================
// PAYROLL SUMMARY
// =============================================================================

/// Aggregated summary of payroll calculations for a pay period.
@freezed
abstract class PayrollSummary with _$PayrollSummary {
  const PayrollSummary._();

  const factory PayrollSummary({
    /// Individual payroll calculations.
    required List<PayrollCalculation> calculations,

    /// Sum of all gross salaries.
    required double totalGross,

    /// Sum of all deductions.
    required double totalDeductions,

    /// Sum of all net pay amounts.
    required double totalNet,
  }) = _PayrollSummary;

  factory PayrollSummary.fromJson(Map<String, dynamic> json) =>
      _$PayrollSummaryFromJson(json);

  /// Creates an empty summary with no calculations.
  factory PayrollSummary.empty() => const PayrollSummary(
        calculations: [],
        totalGross: 0,
        totalDeductions: 0,
        totalNet: 0,
      );

  /// Creates a summary by aggregating a list of calculations.
  factory PayrollSummary.fromCalculations(List<PayrollCalculation> calculations) {
    if (calculations.isEmpty) return PayrollSummary.empty();

    final totalGross = calculations.fold<double>(
      0,
      (sum, calc) => sum + calc.totalGrossEarnings,
    );
    final totalDeductions = calculations.fold<double>(
      0,
      (sum, calc) => sum + calc.totalDeductions,
    );
    final totalNet = calculations.fold<double>(
      0,
      (sum, calc) => sum + calc.netPay,
    );

    return PayrollSummary(
      calculations: calculations,
      totalGross: totalGross,
      totalDeductions: totalDeductions,
      totalNet: totalNet,
    );
  }

  /// Number of workers in this summary.
  int get workerCount => calculations.length;

  /// Returns true if there are no calculations.
  bool get isEmpty => calculations.isEmpty;

  /// Returns true if there is at least one calculation.
  bool get isNotEmpty => !isEmpty;

  /// Average gross salary per worker.
  double get averageGross => isEmpty ? 0 : totalGross / workerCount;

  /// Average net pay per worker.
  double get averageNet => isEmpty ? 0 : totalNet / workerCount;

  /// Effective deduction rate as a percentage.
  double get effectiveDeductionRate =>
      totalGross == 0 ? 0 : (totalDeductions / totalGross) * 100;

  /// Calculations filtered by status.
  List<PayrollCalculation> byStatus(String status) =>
      calculations.where((c) => c.status == status).toList();

  /// Count of calculations by status.
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    for (final calc in calculations) {
      counts[calc.status] = (counts[calc.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Aggregated tax breakdown across all calculations.
  TaxBreakdown get aggregatedTaxBreakdown {
    if (isEmpty) return TaxBreakdown.zero();

    return TaxBreakdown(
      nssf: calculations.fold(0, (sum, c) => sum + c.taxBreakdown.nssf),
      nhif: calculations.fold(0, (sum, c) => sum + c.taxBreakdown.nhif),
      housingLevy: calculations.fold(0, (sum, c) => sum + c.taxBreakdown.housingLevy),
      paye: calculations.fold(0, (sum, c) => sum + c.taxBreakdown.paye),
      totalDeductions: calculations.fold(0, (sum, c) => sum + c.taxBreakdown.totalDeductions),
    );
  }

  /// Validates that totals match the sum of individual calculations.
  bool get isValid {
    final calculatedGross = calculations.fold<double>(
      0,
      (sum, calc) => sum + calc.totalGrossEarnings,
    );
    final calculatedNet = calculations.fold<double>(
      0,
      (sum, calc) => sum + calc.netPay,
    );

    return (totalGross - calculatedGross).abs() < 0.01 &&
        (totalNet - calculatedNet).abs() < 0.01;
  }
}

// =============================================================================
// FUND VERIFICATION RESULT
// =============================================================================

/// Result of pre-payroll fund verification check.
class FundVerificationResult {
  /// Total amount required to process payroll (sum of net pay for all workers)
  final double requiredAmount;

  /// User's current available wallet balance
  final double availableBalance;

  /// User's uncleared wallet balance
  final double clearingBalance;

  /// Whether the user can proceed with payroll (balance >= required)
  final bool canProceed;

  /// Shortfall amount if insufficient funds (0 if sufficient)
  final double shortfall;

  /// Number of workers included in this calculation
  final int workerCount;

  const FundVerificationResult({
    required this.requiredAmount,
    required this.availableBalance,
    this.clearingBalance = 0.0,
    required this.canProceed,
    required this.shortfall,
    required this.workerCount,
  });

  factory FundVerificationResult.fromJson(Map<String, dynamic> json) {
    return FundVerificationResult(
      requiredAmount: (json['requiredAmount'] as num?)?.toDouble() ?? 0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
      clearingBalance: (json['clearingBalance'] as num?)?.toDouble() ?? 0,
      canProceed: json['canProceed'] as bool? ?? false,
      shortfall: (json['shortfall'] as num?)?.toDouble() ?? 0,
      workerCount: json['workerCount'] as int? ?? 0,
    );
  }

  /// Returns true if user has sufficient funds
  bool get hasSufficientFunds => canProceed;

  /// Returns formatted shortfall for display
  String get formattedShortfall => 'KES ${shortfall.toStringAsFixed(2)}';

  /// Returns formatted required amount for display
  String get formattedRequired => 'KES ${requiredAmount.toStringAsFixed(2)}';

  /// Returns formatted balance for display
  String get formattedBalance => 'KES ${availableBalance.toStringAsFixed(2)}';

  /// Returns formatted clearing balance for display
  String get formattedClearing => 'KES ${clearingBalance.toStringAsFixed(2)}';
}

// =============================================================================
// PAYROLL PROCESSING RESULT
// =============================================================================

/// Result of batch payroll processing.

@freezed
abstract class PayrollProcessingResult with _$PayrollProcessingResult {
  const PayrollProcessingResult._();

  const factory PayrollProcessingResult({
    /// Number of successfully processed workers
    required int successCount,

    /// Number of failed worker payments
    required int failureCount,

    /// Individual results for each worker
    required List<WorkerPaymentResult> results,

    /// Bank file content for bank transfers (if applicable)
    String? bankFile,

    /// List of worker IDs for payments that failed.
    @Default([]) List<String> failedWorkerIds,
  }) = _PayrollProcessingResult;

  factory PayrollProcessingResult.fromJson(Map<String, dynamic> json) =>
      _$PayrollProcessingResultFromJson(json);

  /// Returns true if all payments succeeded
  bool get allSuccessful => failureCount == 0;

  /// Alias for allSuccessful
  bool get isFullSuccess => allSuccessful;

  /// Returns true if some payments succeeded and some failed
  bool get isPartialSuccess => successCount > 0 && failureCount > 0;

  /// Returns true if all payments failed
  bool get isFullFailure => successCount == 0 && failureCount > 0;

  /// Total number of workers processed
  int get totalCount => successCount + failureCount;
  
  /// Backward consistency alias
  int get totalProcessed => totalCount;
}

/// Result of a single worker's payment processing.
@JsonSerializable()
class WorkerPaymentResult {
  final String workerId;
  final String workerName;
  final bool success;
  final double? netPay;
  final String? transactionId;
  final String? error;

  const WorkerPaymentResult({
    required this.workerId,
    required this.workerName,
    required this.success,
    this.netPay,
    this.transactionId,
    this.error,
  });

  factory WorkerPaymentResult.fromJson(Map<String, dynamic> json) =>
      _$WorkerPaymentResultFromJson(json);

  Map<String, dynamic> toJson() => _$WorkerPaymentResultToJson(this);
}


/// Preview data for a payslip (without PDF).
class PayslipPreview {
  final String workerName;
  final String payPeriodName;
  final double grossPay;
  final double netPay;
  final double totalDeductions;
  final Map<String, double> earnings;
  final Map<String, double> deductions;
  final DateTime generatedAt;

  const PayslipPreview({
    required this.workerName,
    required this.payPeriodName,
    required this.grossPay,
    required this.netPay,
    required this.totalDeductions,
    required this.earnings,
    required this.deductions,
    required this.generatedAt,
  });

  factory PayslipPreview.fromJson(Map<String, dynamic> json) {
    return PayslipPreview(
      workerName: json['workerName'] as String? ?? '',
      payPeriodName: json['payPeriodName'] as String? ?? '',
      grossPay: (json['grossPay'] as num?)?.toDouble() ?? 0,
      netPay: (json['netPay'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      earnings: _parseDoubleMap(json['earnings']),
      deductions: _parseDoubleMap(json['deductions']),
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, double> _parseDoubleMap(dynamic data) {
    if (data is! Map) return {};
    return data.map(
      (key, value) => MapEntry(
        key as String,
        (value as num?)?.toDouble() ?? 0,
      ),
    );
  }
}