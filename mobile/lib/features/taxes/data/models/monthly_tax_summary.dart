class MonthlyTaxSummary {
  final int year;
  final int month;
  final String monthName;
  final double totalPaye;
  final double totalNssf;
  final double totalNhif;
  final double totalHousingLevy;
  final double totalTax;
  final String status; // PENDING or FILED
  final List<dynamic> submissions;
  final List<String> submissionIds;

  const MonthlyTaxSummary({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalPaye,
    required this.totalNssf,
    required this.totalNhif,
    required this.totalHousingLevy,
    required this.totalTax,
    required this.status,
    required this.submissions,
    required this.submissionIds,
  });

  factory MonthlyTaxSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyTaxSummary(
      year: json['year'] as int,
      month: json['month'] as int,
      monthName: json['monthName'] as String,
      totalPaye: (json['totalPaye'] as num).toDouble(),
      totalNssf: (json['totalNssf'] as num).toDouble(),
      totalNhif: (json['totalNhif'] as num).toDouble(),
      totalHousingLevy: (json['totalHousingLevy'] as num).toDouble(),
      totalTax: (json['totalTax'] as num).toDouble(),
      status: json['status'] as String,
      submissions: json['submissions'] as List<dynamic>,
      submissionIds: (json['submissionIds'] as List).cast<String>(),
    );
  }
}
