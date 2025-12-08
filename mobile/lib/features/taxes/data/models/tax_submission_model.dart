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
    return TaxSubmissionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      taxYear: json['taxYear'] as String,
      income: double.tryParse(json['income'].toString()) ?? 0.0,
      deductions: double.tryParse(json['deductions'].toString()) ?? 0.0,
      taxableIncome: double.tryParse(json['taxableIncome'].toString()) ?? 0.0,
      taxDue: double.tryParse(json['taxDue'].toString()) ?? 0.0,
      status: json['status'] as String,
      filingDate: json['filingDate'] != null 
          ? DateTime.parse(json['filingDate'] as String)
          : null,
      kraReference: json['kraReference'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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