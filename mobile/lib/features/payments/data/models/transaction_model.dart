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
      paymentMethod: json['paymentMethod'] ?? json['provider'] ?? 'unknown',
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
  final String userId;
  final String workerId;
  final String workerName;
  final String periodStart;
  final String periodEnd;
  final double grossSalary;
  final double netSalary;
  final double taxAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentDate;
  final Map<String, dynamic>? taxBreakdown;
  final Map<String, dynamic>? deductions;
  final String createdAt;

  PayrollRecordModel({
    required this.id,
    required this.userId,
    required this.workerId,
    required this.workerName,
    required this.periodStart,
    required this.periodEnd,
    required this.grossSalary,
    required this.netSalary,
    required this.taxAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentDate,
    this.taxBreakdown,
    this.deductions,
    required this.createdAt,
  });

  factory PayrollRecordModel.fromJson(Map<String, dynamic> json) {
    return PayrollRecordModel(
      id: json['id'],
      userId: json['userId'],
      workerId: json['workerId'],
      workerName: json['workerName'] ?? json['worker']?['full_name'] ?? 'Unknown',
      periodStart: json['periodStart'],
      periodEnd: json['periodEnd'],
      grossSalary: double.parse(json['grossSalary'].toString()),
      netSalary: double.parse(json['netSalary'].toString()),
      taxAmount: double.parse(json['taxAmount'].toString()),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'mpesa',
      paymentDate: json['paymentDate'],
      taxBreakdown: json['taxBreakdown'],
      deductions: json['deductions'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workerId': workerId,
      'workerName': workerName,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'taxAmount': taxAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'taxBreakdown': taxBreakdown,
      'deductions': deductions,
      'createdAt': createdAt,
    };
  }
}