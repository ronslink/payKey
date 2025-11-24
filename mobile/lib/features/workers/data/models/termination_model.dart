enum TerminationReason {
  resignation,
  termination,
  retirement,
  endOfContract,
  other;

  String get displayName {
    switch (this) {
      case TerminationReason.resignation:
        return 'Resignation';
      case TerminationReason.termination:
        return 'Termination';
      case TerminationReason.retirement:
        return 'Retirement';
      case TerminationReason.endOfContract:
        return 'End of Contract';
      case TerminationReason.other:
        return 'Other';
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
      reason: TerminationReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => TerminationReason.other,
      ),
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
      'reason': reason.name,
      'noticePeriodDays': noticePeriodDays,
      'severancePay': severancePay,
      'outstandingPayments': outstandingPayments,
      'notes': notes,
    };
  }
}
