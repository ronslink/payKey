/// Termination reasons - must match backend TerminationReason enum exactly
enum TerminationReason {
  resignation,
  dismissal,  // Maps to DISMISSAL in backend (was 'termination')
  contractEnd, // Maps to CONTRACT_END in backend
  illness,
  death,
  retirement,
  redundancy,
  other;

  /// Returns the display name for UI presentation
  String get displayName {
    switch (this) {
      case TerminationReason.resignation:
        return 'Resignation';
      case TerminationReason.dismissal:
        return 'Dismissal';
      case TerminationReason.contractEnd:
        return 'End of Contract';
      case TerminationReason.illness:
        return 'Illness';
      case TerminationReason.death:
        return 'Death';
      case TerminationReason.retirement:
        return 'Retirement';
      case TerminationReason.redundancy:
        return 'Redundancy';
      case TerminationReason.other:
        return 'Other';
    }
  }

  /// Returns the backend enum value (UPPERCASE, snake_case for multi-word)
  String get backendValue {
    switch (this) {
      case TerminationReason.resignation:
        return 'RESIGNATION';
      case TerminationReason.dismissal:
        return 'DISMISSAL';
      case TerminationReason.contractEnd:
        return 'CONTRACT_END';
      case TerminationReason.illness:
        return 'ILLNESS';
      case TerminationReason.death:
        return 'DEATH';
      case TerminationReason.retirement:
        return 'RETIREMENT';
      case TerminationReason.redundancy:
        return 'REDUNDANCY';
      case TerminationReason.other:
        return 'OTHER';
    }
  }

  /// Parse from backend value (handles UPPERCASE)
  static TerminationReason fromBackend(String value) {
    switch (value.toUpperCase()) {
      case 'RESIGNATION':
        return TerminationReason.resignation;
      case 'DISMISSAL':
        return TerminationReason.dismissal;
      case 'CONTRACT_END':
        return TerminationReason.contractEnd;
      case 'ILLNESS':
        return TerminationReason.illness;
      case 'DEATH':
        return TerminationReason.death;
      case 'RETIREMENT':
        return TerminationReason.retirement;
      case 'REDUNDANCY':
        return TerminationReason.redundancy;
      case 'OTHER':
      default:
        return TerminationReason.other;
    }
  }
}

class Termination {
  final String id;
  final String workerId;
  final String workerName;
  final String terminationDate;
  final TerminationReason reason;
  final int noticePeriodDays;
  final double proratedSalary;
  final double unusedLeavePayout;
  final double severancePay;
  final double totalFinalPayment;
  final String? notes;
  
  Termination({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.terminationDate,
    required this.reason,
    this.noticePeriodDays = 0,
    this.proratedSalary = 0,
    this.unusedLeavePayout = 0,
    this.severancePay = 0,
    this.totalFinalPayment = 0,
    this.notes,
  });
  
  factory Termination.fromJson(Map<String, dynamic> json) {
    return Termination(
      id: json['id'],
      workerId: json['workerId'],
      workerName: json['workerName'] ?? 'Unknown',
      terminationDate: json['terminationDate'],
      reason: TerminationReason.fromBackend(json['reason'] ?? 'OTHER'),
      noticePeriodDays: json['noticePeriodDays'] ?? 0,
      proratedSalary: (json['proratedSalary'] ?? 0).toDouble(),
      unusedLeavePayout: (json['unusedLeavePayout'] ?? 0).toDouble(),
      severancePay: (json['severancePay'] ?? 0).toDouble(),
      totalFinalPayment: (json['totalFinalPayment'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }
}

class FinalPaymentCalculation {
  final double proratedSalary;
  final double unusedLeavePayout;
  final double severancePay;
  final double taxDeductions;
  final double totalFinalPayment;
  final String calculationDate;

  FinalPaymentCalculation({
    required this.proratedSalary,
    required this.unusedLeavePayout,
    required this.severancePay,
    required this.taxDeductions,
    required this.totalFinalPayment,
    required this.calculationDate,
  });

  factory FinalPaymentCalculation.fromJson(Map<String, dynamic> json) {
    return FinalPaymentCalculation(
      proratedSalary: (json['proratedSalary'] ?? 0).toDouble(),
      unusedLeavePayout: (json['unusedLeavePayout'] ?? 0).toDouble(),
      severancePay: (json['severancePay'] ?? 0).toDouble(),
      taxDeductions: (json['taxDeductions'] ?? 0).toDouble(),
      totalFinalPayment: (json['totalFinalPayment'] ?? 0).toDouble(),
      calculationDate: json['calculationDate'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class TerminationRequest {
  final String terminationDate;
  final TerminationReason reason;
  final int noticePeriodDays;
  final double severancePay;
  final double outstandingPayments;
  final String? notes;

  TerminationRequest({
    required this.terminationDate,
    required this.reason,
    this.noticePeriodDays = 0,
    this.severancePay = 0,
    this.outstandingPayments = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'terminationDate': terminationDate,
      'reason': reason.backendValue,
      'noticePeriodDays': noticePeriodDays,
      'severancePay': severancePay,
      'outstandingPayments': outstandingPayments,
      'notes': notes,
    };
  }
}
