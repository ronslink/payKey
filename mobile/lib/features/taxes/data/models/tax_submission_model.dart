class TaxSubmissionModel {
  final String id;
  final String userId;
  final String taxYear;
  final double income;
  final double deductions;
  final double taxableIncome;
  final double taxDue;
  final String status; // 'draft', 'filed', 'approved', 'rejected'
  final DateTime? filingDate;
  final String? kraReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaxSubmissionModel({
    required this.id,
    required this.userId,
    required this.taxYear,
    required this.income,
    required this.deductions,
    required this.taxableIncome,
    required this.taxDue,
    required this.status,
    this.filingDate,
    this.kraReference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaxSubmissionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested payPeriod if available
    final payPeriod = json['payPeriod'] as Map<String, dynamic>?;
    
    // Determine tax year/period name
    String year = json['taxYear'] as String? ?? '';
    
    // Try to get Period Name first (e.g. "June 2025")
    if (payPeriod != null && payPeriod['name'] != null) {
      year = payPeriod['name'].toString();
    }
    // Fallback to year from date
    else if (year.isEmpty && payPeriod != null && payPeriod['endDate'] != null) {
      final endDate = DateTime.tryParse(payPeriod['endDate'].toString());
      if (endDate != null) year = endDate.year.toString();
    }
    else if (year.isEmpty && json['createdAt'] != null) {
       final created = DateTime.tryParse(json['createdAt'].toString());
       if (created != null) year = created.year.toString();
    }

    // Determine income from payPeriod totalGrossAmount
    double inc = double.tryParse(json['income'].toString()) ?? 0.0;
    if (inc == 0.0 && payPeriod != null) {
      inc = double.tryParse(payPeriod['totalGrossAmount'].toString()) ?? 0.0;
    }

    // Determine taxDue (Total of all taxes or just PAYE?)
    // Using totalPaye + totalNssf + totalNhif + totalHousingLevy if available
    double due = double.tryParse(json['taxDue'].toString()) ?? 0.0;
    if (due == 0.0) {
      final paye = double.tryParse(json['totalPaye'].toString()) ?? 0.0;
      final nssf = double.tryParse(json['totalNssf'].toString()) ?? 0.0;
      final nhif = double.tryParse(json['totalNhif'].toString()) ?? 0.0;
      final housing = double.tryParse(json['totalHousingLevy'].toString()) ?? 0.0;
      due = paye + nssf + nhif + housing;
    }

    // Determine status (lowercase/uppercase normalization)
    String stat = (json['status'] as String? ?? 'draft').toLowerCase();

    return TaxSubmissionModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      taxYear: year,
      income: inc,
      deductions: double.tryParse(json['deductions'].toString()) ?? 0.0,
      taxableIncome: double.tryParse(json['taxableIncome'].toString()) ?? 0.0,
      taxDue: due,
      status: stat,
      filingDate: json['filingDate'] != null 
          ? DateTime.parse(json['filingDate'] as String)
          : null,
      kraReference: json['kraReference'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taxYear': taxYear,
      'income': income,
      'deductions': deductions,
      'taxableIncome': taxableIncome,
      'taxDue': taxDue,
      'status': status,
      'filingDate': filingDate?.toIso8601String(),
      'kraReference': kraReference,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TaxSubmissionModel copyWith({
    String? id,
    String? userId,
    String? taxYear,
    double? income,
    double? deductions,
    double? taxableIncome,
    double? taxDue,
    String? status,
    DateTime? filingDate,
    String? kraReference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxSubmissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taxYear: taxYear ?? this.taxYear,
      income: income ?? this.income,
      deductions: deductions ?? this.deductions,
      taxableIncome: taxableIncome ?? this.taxableIncome,
      taxDue: taxDue ?? this.taxDue,
      status: status ?? this.status,
      filingDate: filingDate ?? this.filingDate,
      kraReference: kraReference ?? this.kraReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}