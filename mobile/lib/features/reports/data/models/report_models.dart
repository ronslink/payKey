
class PayrollSummaryReport {
  final ReportPayPeriod payPeriod;
  final ReportTotals totals;
  final List<PayrollRecordSummary> records;

  PayrollSummaryReport({
    required this.payPeriod,
    required this.totals,
    required this.records,
  });

  factory PayrollSummaryReport.fromJson(Map<String, dynamic> json) {
    return PayrollSummaryReport(
      payPeriod: ReportPayPeriod.fromJson(json['payPeriod']),
      totals: ReportTotals.fromJson(json['totals']),
      records: (json['records'] as List)
          .map((e) => PayrollRecordSummary.fromJson(e))
          .toList(),
    );
  }
}

class StatutoryReport {
  final ReportPayPeriod payPeriod;
  final ReportTotals totals;
  final List<StatutoryEmployeeRecord> employees;

  StatutoryReport({
    required this.payPeriod,
    required this.totals,
    required this.employees,
  });

  factory StatutoryReport.fromJson(Map<String, dynamic> json) {
    return StatutoryReport(
      payPeriod: ReportPayPeriod.fromJson(json['payPeriod']),
      totals: ReportTotals.fromJson(json['totals']),
      employees: (json['employees'] as List)
          .map((e) => StatutoryEmployeeRecord.fromJson(e))
          .toList(),
    );
  }
}

class ReportPayPeriod {
  final String id;
  final String startDate;
  final String endDate;

  ReportPayPeriod({required this.id, required this.startDate, required this.endDate});

  factory ReportPayPeriod.fromJson(Map<String, dynamic> json) {
    return ReportPayPeriod(
      id: json['id'],
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}

class ReportTotals {
  final double grossPay;
  final double netPay;
  final double paye;
  final double nssf;
  final double shif;
  final double housingLevy;
  final double totalDeductions;
  final int? workerCount;

  ReportTotals({
    required this.grossPay,
    required this.netPay,
    required this.paye,
    required this.nssf,
    required this.shif,
    required this.housingLevy,
    required this.totalDeductions,
    this.workerCount,
  });

  factory ReportTotals.fromJson(Map<String, dynamic> json) {
    return ReportTotals(
      grossPay: (json['grossPay'] as num?)?.toDouble() ?? 0,
      netPay: (json['netPay'] as num?)?.toDouble() ?? 0,
      paye: (json['paye'] as num?)?.toDouble() ?? 0,
      nssf: (json['nssf'] as num?)?.toDouble() ?? 0,
      shif: (json['nhif'] as num?)?.toDouble() ?? 0,
      housingLevy: (json['housingLevy'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      workerCount: json['workerCount'] as int?,
    );
  }
}

class PayrollRecordSummary {
  final String id;
  final String workerName;
  final String workerId;
  final double grossPay;
  final double netPay;
  final ReportTaxBreakdown taxBreakdown;

  PayrollRecordSummary({
    required this.id,
    required this.workerName,
    required this.workerId,
    required this.grossPay,
    required this.netPay,
    required this.taxBreakdown,
  });

  factory PayrollRecordSummary.fromJson(Map<String, dynamic> json) {
    return PayrollRecordSummary(
      id: json['id'] ?? '', // Default to empty string if missing (backwards compat)
      workerName: json['workerName'],
      workerId: json['workerId'],
      grossPay: (json['grossPay'] as num).toDouble(),
      netPay: (json['netPay'] as num).toDouble(),
      taxBreakdown: ReportTaxBreakdown.fromJson(json['taxBreakdown']),
    );
  }
}

class ReportTaxBreakdown {
  final double paye;
  final double nssf;
  final double shif;
  final double housingLevy;
  final double total;

  ReportTaxBreakdown({
    required this.paye,
    required this.nssf,
    required this.shif,
    required this.housingLevy,
    required this.total,
  });

  factory ReportTaxBreakdown.fromJson(Map<String, dynamic> json) {
    return ReportTaxBreakdown(
      paye: (json['paye'] as num).toDouble(),
      nssf: (json['nssf'] as num).toDouble(),
      shif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class StatutoryEmployeeRecord {
  final String name;
  final double grossPay;
  final double nssf;
  final double shif;
  final double housingLevy;
  final double paye;

  StatutoryEmployeeRecord({
    required this.name,
    required this.grossPay,
    required this.nssf,
    required this.shif,
    required this.housingLevy,
    required this.paye,
  });

  factory StatutoryEmployeeRecord.fromJson(Map<String, dynamic> json) {
    return StatutoryEmployeeRecord(
      name: json['name'],
      grossPay: (json['grossPay'] as num).toDouble(),
      nssf: (json['nssf'] as num).toDouble(),
      shif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      paye: (json['paye'] as num).toDouble(),
    );
  }
}

/// P9 Report - Kenya P9A Tax Deduction Card
class P9Report {
  final String workerId;
  final String workerName;
  final String kraPin;
  final List<P9MonthData> months;
  final P9Totals totals;

  P9Report({
    required this.workerId,
    required this.workerName,
    required this.kraPin,
    required this.months,
    required this.totals,
  });

  factory P9Report.fromJson(Map<String, dynamic> json) {
    return P9Report(
      workerId: json['workerId'] ?? '',
      workerName: json['workerName'] ?? 'Unknown',
      kraPin: json['kraPin'] ?? '',
      months: (json['months'] as List?)
              ?.map((e) => P9MonthData.fromJson(e))
              .toList() ??
          [],
      totals: P9Totals.fromJson(json['totals'] ?? {}),
    );
  }

  /// Calculate total PAYE for quick display
  double get totalPaye => totals.paye;

  /// Calculate total gross for quick display
  double get totalGross => totals.grossPay;

  /// Get months with actual data (non-zero gross)
  List<P9MonthData> get activeMonths =>
      months.where((m) => m.grossPay > 0).toList();
}

class P9MonthData {
  final int month;
  final double basicSalary;
  final double benefits;
  final double valueOfQuarters;
  final double grossPay;
  final double contribution; // NSSF
  final double ownerOccupiedInterest;
  final double retirementContribution;
  final double taxablePay;
  final double taxCharged;
  final double relief;
  final double paye;

  P9MonthData({
    required this.month,
    required this.basicSalary,
    required this.benefits,
    required this.valueOfQuarters,
    required this.grossPay,
    required this.contribution,
    required this.ownerOccupiedInterest,
    required this.retirementContribution,
    required this.taxablePay,
    required this.taxCharged,
    required this.relief,
    required this.paye,
  });

  factory P9MonthData.fromJson(Map<String, dynamic> json) {
    return P9MonthData(
      month: json['month'] ?? 1,
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
      benefits: (json['benefits'] as num?)?.toDouble() ?? 0,
      valueOfQuarters: (json['valueOfQuarters'] as num?)?.toDouble() ?? 0,
      grossPay: (json['grossPay'] as num?)?.toDouble() ?? 0,
      contribution: (json['contribution'] as num?)?.toDouble() ?? 0,
      ownerOccupiedInterest:
          (json['ownerOccupiedInterest'] as num?)?.toDouble() ?? 0,
      retirementContribution:
          (json['retirementContribution'] as num?)?.toDouble() ?? 0,
      taxablePay: (json['taxablePay'] as num?)?.toDouble() ?? 0,
      taxCharged: (json['taxCharged'] as num?)?.toDouble() ?? 0,
      relief: (json['relief'] as num?)?.toDouble() ?? 0,
      paye: (json['paye'] as num?)?.toDouble() ?? 0,
    );
  }

  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1) % 12];
  }

  String get fullMonthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(month - 1) % 12];
  }
}

class P9Totals {
  final double basicSalary;
  final double grossPay;
  final double paye;

  P9Totals({
    required this.basicSalary,
    required this.grossPay,
    required this.paye,
  });

  factory P9Totals.fromJson(Map<String, dynamic> json) {
    return P9Totals(
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
      grossPay: (json['grossPay'] as num?)?.toDouble() ?? 0,
      paye: (json['paye'] as num?)?.toDouble() ?? 0,
    );
  }
}
