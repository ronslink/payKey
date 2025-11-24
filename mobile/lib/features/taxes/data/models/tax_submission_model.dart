class TaxSubmissionModel {
  final String id;
  final String payPeriodId;
  final double totalPaye;
  final double totalNssf;
  final double totalNhif;
  final double totalHousingLevy;
  final String status;
  final DateTime? filingDate;
  final DateTime createdAt;

  TaxSubmissionModel({
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

  factory TaxSubmissionModel.fromJson(Map<String, dynamic> json) {
    return TaxSubmissionModel(
      id: json['id'],
      payPeriodId: json['payPeriodId'],
      totalPaye: double.parse(json['totalPaye'].toString()),
      totalNssf: double.parse(json['totalNssf'].toString()),
      totalNhif: double.parse(json['totalNhif'].toString()),
      totalHousingLevy: double.parse(json['totalHousingLevy'].toString()),
      status: json['status'],
      filingDate: json['filingDate'] != null
          ? DateTime.parse(json['filingDate'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  double get totalTax =>
      totalPaye + totalNssf + totalNhif + totalHousingLevy;
}
