// Unified Financial Record Model
// Handles both transactions and payroll records through type differentiation
class FinancialRecordModel {
  final String id;
  final String type; // 'transaction' | 'payroll'
  final String? userId;
  final String? workerId;
  final String? payPeriodId;
  final double amount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? processedAt;
  final Map<String, dynamic>? metadata;

  // Payroll-specific fields (nullable for transactions)
  final String? workerName;
  final double? grossSalary;
  final double? netSalary;
  final double? taxAmount;
  final List<String>? deductions;

  FinancialRecordModel({
    required this.id,
    required this.type,
    this.userId,
    this.workerId,
    this.payPeriodId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.processedAt,
    this.metadata,
    // Payroll fields
    this.workerName,
    this.grossSalary,
    this.netSalary,
    this.taxAmount,
    this.deductions,
  });

  // Create from TransactionModel
  factory FinancialRecordModel.fromTransaction(TransactionModel transaction) {
    return FinancialRecordModel(
      id: transaction.id,
      type: 'transaction',
      userId: transaction.userId,
      amount: transaction.amount,
      currency: transaction.currency,
      status: transaction.status,
      paymentMethod: transaction.paymentMethod,
      createdAt: DateTime.parse(transaction.createdAt),
      processedAt: transaction.succeededAt != null 
          ? DateTime.parse(transaction.succeededAt!) 
          : null,
      metadata: transaction.metadata,
    );
  }

  // Create from PayrollRecordModel
  factory FinancialRecordModel.fromPayrollRecord(PayrollRecordModel record) {
    return FinancialRecordModel(
      id: record.id,
      type: 'payroll',
      workerId: record.workerId,
      payPeriodId: record.payPeriodId,
      amount: record.netSalary,
      currency: 'USD',
      status: record.status,
      createdAt: record.createdAt,
      workerName: record.workerName,
      grossSalary: record.grossSalary,
      netSalary: record.netSalary,
      taxAmount: record.taxAmount,
      deductions: ['tax', 'nssf', 'nhif'], // Default deductions
    );
  }

  // Convert back to TransactionModel if type is transaction
  TransactionModel? toTransaction() {
    if (type != 'transaction') return null;
    
    return TransactionModel(
      id: id,
      userId: userId!,
      amount: amount,
      currency: currency,
      status: status,
      paymentMethod: paymentMethod ?? 'unknown',
      createdAt: createdAt.toIso8601String(),
      succeededAt: processedAt?.toIso8601String(),
      invoiceUrl: metadata?['invoice_url'] as String?,
      stripePaymentIntentId: metadata?['stripe_payment_intent_id'] as String?,
      mpesaTransactionId: metadata?['mpesa_transaction_id'] as String?,
      metadata: metadata,
    );
  }

  // Convert back to PayrollRecordModel if type is payroll
  PayrollRecordModel? toPayrollRecord() {
    if (type != 'payroll') return null;
    
    return PayrollRecordModel(
      id: id,
      payPeriodId: payPeriodId!,
      workerId: workerId!,
      workerName: workerName!,
      grossSalary: grossSalary ?? 0.0,
      netSalary: netSalary ?? 0.0,
      taxAmount: taxAmount ?? 0.0,
      status: status,
      createdAt: createdAt,
    );
  }

  factory FinancialRecordModel.fromJson(Map<String, dynamic> json) {
    return FinancialRecordModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'transaction',
      userId: json['userId']?.toString(),
      workerId: json['workerId']?.toString(),
      payPeriodId: json['payPeriodId']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      processedAt: json['processedAt']?.toString() != null 
          ? DateTime.tryParse(json['processedAt'].toString()) 
          : null,
      metadata: json['metadata'],
      workerName: json['workerName']?.toString(),
      grossSalary: double.tryParse(json['grossSalary']?.toString() ?? '0'),
      netSalary: double.tryParse(json['netSalary']?.toString() ?? '0'),
      taxAmount: double.tryParse(json['taxAmount']?.toString() ?? '0'),
      deductions: json['deductions'] != null 
          ? List<String>.from(json['deductions'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'userId': userId,
      'workerId': workerId,
      'payPeriodId': payPeriodId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'metadata': metadata,
      'workerName': workerName,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'taxAmount': taxAmount,
      'deductions': deductions,
    };
  }

  // Helper methods
  bool get isTransaction => type == 'transaction';
  bool get isPayroll => type == 'payroll';
  bool get isCompleted => status == 'completed' || status == 'processed';
  bool get isPending => status == 'pending' || status == 'processing';
}

// Import the original models for compatibility
class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String createdAt;
  final String? succeededAt;
  final String? invoiceUrl;
  final String? stripePaymentIntentId;
  final String? mpesaTransactionId;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.succeededAt,
    this.invoiceUrl,
    this.stripePaymentIntentId,
    this.mpesaTransactionId,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['userId'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      createdAt: json['createdAt'],
      succeededAt: json['succeeded_at'],
      invoiceUrl: json['invoice_url'],
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      mpesaTransactionId: json['mpesa_transaction_id'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
      'succeeded_at': succeededAt,
      'invoice_url': invoiceUrl,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'mpesa_transaction_id': mpesaTransactionId,
      'metadata': metadata,
    };
  }
}

class PayrollRecordModel {
  final String id;
  final String payPeriodId;
  final String workerId;
  final String workerName;
  final double grossSalary;
  final double netSalary;
  final double taxAmount;
  final String status;
  final DateTime createdAt;

  PayrollRecordModel({
    required this.id,
    required this.payPeriodId,
    required this.workerId,
    required this.workerName,
    required this.grossSalary,
    required this.netSalary,
    required this.taxAmount,
    required this.status,
    required this.createdAt,
  });

  factory PayrollRecordModel.fromJson(Map<String, dynamic> json) {
    return PayrollRecordModel(
      id: json['id']?.toString() ?? '',
      payPeriodId: json['payPeriodId']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? '',
      workerName: json['workerName']?.toString() ?? '',
      grossSalary: double.tryParse(json['grossSalary']?.toString() ?? '0') ?? 0.0,
      netSalary: double.tryParse(json['netSalary']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['taxAmount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payPeriodId': payPeriodId,
      'workerId': workerId,
      'workerName': workerName,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'taxAmount': taxAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}