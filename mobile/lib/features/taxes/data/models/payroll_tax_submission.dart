class PayrollTaxSubmission {
  final String id;
  final String payPeriodId;
  final double totalPaye;
  final double totalNssf;
  final double totalNhif;
  final double totalHousingLevy;
  final String status;
  final DateTime? filingDate;
  final DateTime createdAt;

  const PayrollTaxSubmission({
    required this.id,
    required this.payPeriodId,
    required this.totalPaye,
    required this.totalNssf,
    required this.totalNhif,
    required this.totalHousingLevy,
    required this.status,
    this.filingDate,
    required this.createdAt,
  });

  factory PayrollTaxSubmission.fromJson(Map<String, dynamic> json) {
    return PayrollTaxSubmission(
      id: json['id'] as String,
      payPeriodId: json['payPeriodId'] as String,
      totalPaye: (json['totalPaye'] as num).toDouble(),
      totalNssf: (json['totalNssf'] as num).toDouble(),
      totalNhif: (json['totalNhif'] as num).toDouble(),
      totalHousingLevy: (json['totalHousingLevy'] as num).toDouble(),
      status: json['status'] as String,
      filingDate: json['filingDate'] != null 
          ? DateTime.parse(json['filingDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payPeriodId': payPeriodId,
      'totalPaye': totalPaye,
      'totalNssf': totalNssf,
      'totalNhif': totalNhif,
      'totalHousingLevy': totalHousingLevy,
      'status': status,
      'filingDate': filingDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get totalTax =>
      totalPaye + totalNssf + totalNhif + totalHousingLevy;

  PayrollTaxSubmission copyWith({
    String? id,
    String? payPeriodId,
    double? totalPaye,
    double? totalNssf,
    double? totalNhif,
    double? totalHousingLevy,
    String? status,
    DateTime? filingDate,
    DateTime? createdAt,
  }) {
    return PayrollTaxSubmission(
      id: id ?? this.id,
      payPeriodId: payPeriodId ?? this.payPeriodId,
      totalPaye: totalPaye ?? this.totalPaye,
      totalNssf: totalNssf ?? this.totalNssf,
      totalNhif: totalNhif ?? this.totalNhif,
      totalHousingLevy: totalHousingLevy ?? this.totalHousingLevy,
      status: status ?? this.status,
      filingDate: filingDate ?? this.filingDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
