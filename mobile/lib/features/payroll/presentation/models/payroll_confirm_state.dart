import 'package:flutter/foundation.dart';
import '../../data/models/payroll_model.dart';

// Re-export FundVerificationResult for convenience
export '../../data/models/payroll_model.dart' show FundVerificationResult;

/// State for the payroll confirmation page
@immutable
class PayrollConfirmState {
  final PayrollConfirmStatus status;
  final FundVerificationResult? verification;
  final PayrollBatchResult? batchResult;
  final String? error;

  const PayrollConfirmState({
    this.status = PayrollConfirmStatus.verifying,
    this.verification,
    this.batchResult,
    this.error,
  });

  const PayrollConfirmState.initial() : this();

  bool get isVerifying => status == PayrollConfirmStatus.verifying;
  bool get isProcessing => status == PayrollConfirmStatus.processing;
  bool get hasResults => status == PayrollConfirmStatus.completed;
  bool get hasError => error != null;

  bool get canProceed => verification?.canProceed ?? false;

  PayrollConfirmState copyWith({
    PayrollConfirmStatus? status,
    FundVerificationResult? verification,
    PayrollBatchResult? batchResult,
    String? error,
    bool clearError = false,
  }) {
    return PayrollConfirmState(
      status: status ?? this.status,
      verification: verification ?? this.verification,
      batchResult: batchResult ?? this.batchResult,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollConfirmState &&
        other.status == status &&
        other.verification == verification &&
        other.batchResult == batchResult &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(status, verification, batchResult, error);
}

/// Status enum for the confirmation flow
enum PayrollConfirmStatus {
  verifying,
  ready,
  processing,
  completed,
  error,
}

/// Result of batch payroll processing
@immutable
class PayrollBatchResult {
  final int successCount;
  final int failureCount;
  final int totalProcessed;
  final List<String> failedWorkerIds;
  final List<PayrollWorkerResult> results;

  const PayrollBatchResult({
    required this.successCount,
    required this.failureCount,
    required this.totalProcessed,
    required this.failedWorkerIds,
    required this.results,
  });

  bool get allSuccess => failureCount == 0;
  bool get hasFailures => failureCount > 0;

  /// Create from Map (API response)
  factory PayrollBatchResult.fromMap(Map<String, dynamic> map) {
    final resultsList = (map['results'] as List<dynamic>?) ?? [];
    
    return PayrollBatchResult(
      successCount: map['successCount'] as int? ?? 0,
      failureCount: map['failureCount'] as int? ?? 0,
      totalProcessed: map['totalProcessed'] as int? ?? 0,
      failedWorkerIds: List<String>.from(map['failedWorkerIds'] ?? []),
      results: resultsList
          .map((r) => PayrollWorkerResult.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'successCount': successCount,
      'failureCount': failureCount,
      'totalProcessed': totalProcessed,
      'failedWorkerIds': failedWorkerIds,
      'results': results.map((r) => r.toMap()).toList(),
    };
  }
}

/// Result for a single worker's payroll
@immutable
class PayrollWorkerResult {
  final bool success;
  final String workerName;
  final double netPay;
  final String? error;

  const PayrollWorkerResult({
    required this.success,
    required this.workerName,
    required this.netPay,
    this.error,
  });

  factory PayrollWorkerResult.fromMap(Map<String, dynamic> map) {
    return PayrollWorkerResult(
      success: map['success'] as bool? ?? false,
      workerName: map['workerName'] as String? ?? 'Unknown',
      netPay: (map['netPay'] as num?)?.toDouble() ?? 0.0,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'workerName': workerName,
      'netPay': netPay,
      'error': error,
    };
  }
}
