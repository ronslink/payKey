
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
  final double nhif;
  final double housingLevy;
  final double totalDeductions;
  final int? workerCount;

  ReportTotals({
    required this.grossPay,
    required this.netPay,
    required this.paye,
    required this.nssf,
    required this.nhif,
    required this.housingLevy,
    required this.totalDeductions,
    this.workerCount,
  });

  factory ReportTotals.fromJson(Map<String, dynamic> json) {
    return ReportTotals(
      grossPay: (json['grossPay'] as num).toDouble(),
      netPay: (json['netPay'] as num?)?.toDouble() ?? 0,
      paye: (json['paye'] as num).toDouble(),
      nssf: (json['nssf'] as num).toDouble(),
      nhif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      workerCount: json['workerCount'],
    );
  }
}

class PayrollRecordSummary {
  final String workerName;
  final String workerId;
  final double grossPay;
  final double netPay;
  final ReportTaxBreakdown taxBreakdown;

  PayrollRecordSummary({
    required this.workerName,
    required this.workerId,
    required this.grossPay,
    required this.netPay,
    required this.taxBreakdown,
  });

  factory PayrollRecordSummary.fromJson(Map<String, dynamic> json) {
    return PayrollRecordSummary(
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
  final double nhif;
  final double housingLevy;
  final double total;

  ReportTaxBreakdown({
    required this.paye,
    required this.nssf,
    required this.nhif,
    required this.housingLevy,
    required this.total,
  });

  factory ReportTaxBreakdown.fromJson(Map<String, dynamic> json) {
    return ReportTaxBreakdown(
      paye: (json['paye'] as num).toDouble(),
      nssf: (json['nssf'] as num).toDouble(),
      nhif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class StatutoryEmployeeRecord {
  final String name;
  final double grossPay;
  final double nssf;
  final double nhif;
  final double housingLevy;
  final double paye;

  StatutoryEmployeeRecord({
    required this.name,
    required this.grossPay,
    required this.nssf,
    required this.nhif,
    required this.housingLevy,
    required this.paye,
  });

  factory StatutoryEmployeeRecord.fromJson(Map<String, dynamic> json) {
    return StatutoryEmployeeRecord(
      name: json['name'],
      grossPay: (json['grossPay'] as num).toDouble(),
      nssf: (json['nssf'] as num).toDouble(),
      nhif: (json['nhif'] as num).toDouble(),
      housingLevy: (json['housingLevy'] as num).toDouble(),
      paye: (json['paye'] as num).toDouble(),
    );
  }
}
