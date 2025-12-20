class PayPeriodModel {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String? payDate;
  final PayPeriodFrequency frequency;
  final PayPeriodStatus status;
  final double totalGrossAmount;
  final double totalNetAmount;
  final double totalTaxAmount;
  final int totalWorkers;
  final int processedWorkers;
  final Map<String, dynamic>? notes;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayPeriodModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.payDate,
    required this.frequency,
    required this.status,
    this.totalGrossAmount = 0,
    this.totalNetAmount = 0,
    this.totalTaxAmount = 0,
    this.totalWorkers = 0,
    this.processedWorkers = 0,
    this.notes,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayPeriodModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse numeric values that may be strings or numbers
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PayPeriodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      payDate: json['payDate'] as String?,
      frequency: PayPeriodFrequency.fromString(json['frequency'] as String),
      status: PayPeriodStatus.fromString(json['status'] as String),
      totalGrossAmount: parseDouble(json['totalGrossAmount']),
      totalNetAmount: parseDouble(json['totalNetAmount']),
      totalTaxAmount: parseDouble(json['totalTaxAmount']),
      totalWorkers: parseInt(json['totalWorkers']),
      processedWorkers: parseInt(json['processedWorkers']),
      notes: json['notes'] as Map<String, dynamic>?,
      createdBy: json['createdBy'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'payDate': payDate,
      'frequency': frequency.value,
      'status': status.value,
      'totalGrossAmount': totalGrossAmount,
      'totalNetAmount': totalNetAmount,
      'totalTaxAmount': totalTaxAmount,
      'totalWorkers': totalWorkers,
      'processedWorkers': processedWorkers,
      'notes': notes,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PayPeriodModel copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    String? payDate,
    PayPeriodFrequency? frequency,
    PayPeriodStatus? status,
    double? totalGrossAmount,
    double? totalNetAmount,
    double? totalTaxAmount,
    int? totalWorkers,
    int? processedWorkers,
    Map<String, dynamic>? notes,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayPeriodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      payDate: payDate ?? this.payDate,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      totalGrossAmount: totalGrossAmount ?? this.totalGrossAmount,
      totalNetAmount: totalNetAmount ?? this.totalNetAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      totalWorkers: totalWorkers ?? this.totalWorkers,
      processedWorkers: processedWorkers ?? this.processedWorkers,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedPeriod {
    return '$name ($startDate to $endDate)';
  }

  bool get canActivate => status == PayPeriodStatus.draft;
  bool get canProcess => 
      status == PayPeriodStatus.draft || status == PayPeriodStatus.active;
  bool get canComplete => status == PayPeriodStatus.processing;
  bool get canClose => 
      status == PayPeriodStatus.active || 
      status == PayPeriodStatus.processing || 
      status == PayPeriodStatus.completed;
  bool get canEdit => status == PayPeriodStatus.draft;
  bool get canDelete => 
      status != PayPeriodStatus.processing && 
      status != PayPeriodStatus.completed && 
      status != PayPeriodStatus.closed;

  String get statusDisplayText {
    switch (status) {
      case PayPeriodStatus.draft:
        return 'Draft';
      case PayPeriodStatus.active:
        return 'Active';
      case PayPeriodStatus.processing:
        return 'Processing';
      case PayPeriodStatus.completed:
        return 'Completed';
      case PayPeriodStatus.closed:
        return 'Closed';
    }
  }

  String get frequencyDisplayText {
    switch (frequency) {
      case PayPeriodFrequency.weekly:
        return 'Weekly';
      case PayPeriodFrequency.biweekly:
        return 'Bi-weekly';
      case PayPeriodFrequency.monthly:
        return 'Monthly';
      case PayPeriodFrequency.quarterly:
        return 'Quarterly';
    }
  }
}

enum PayPeriodFrequency {
  weekly('WEEKLY'),
  biweekly('BIWEEKLY'),
  monthly('MONTHLY'),
  quarterly('QUARTERLY');

  const PayPeriodFrequency(this.value);
  
  final String value;

  static PayPeriodFrequency fromString(String value) {
    return PayPeriodFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PayPeriodFrequency.monthly,
    );
  }
}

enum PayPeriodStatus {
  draft('DRAFT'),
  active('ACTIVE'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  closed('CLOSED');

  const PayPeriodStatus(this.value);
  
  final String value;

  static PayPeriodStatus fromString(String value) {
    return PayPeriodStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PayPeriodStatus.draft,
    );
  }
}
