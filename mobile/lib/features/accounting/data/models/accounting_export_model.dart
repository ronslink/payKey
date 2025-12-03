class AccountingExport {
  final String id;
  final String payPeriodId;
  final String format;
  final String status;
  final DateTime createdAt;
  final String? payPeriodName; // Derived from relation if available

  AccountingExport({
    required this.id,
    required this.payPeriodId,
    required this.format,
    required this.status,
    required this.createdAt,
    this.payPeriodName,
  });

  factory AccountingExport.fromJson(Map<String, dynamic> json) {
    return AccountingExport(
      id: json['id'],
      payPeriodId: json['payPeriodId'],
      format: json['format'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      payPeriodName: json['payPeriod'] != null ? json['payPeriod']['name'] : null,
    );
  }
}
