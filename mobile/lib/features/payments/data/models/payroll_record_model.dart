// This is the actual model used by the payments module
// It bridges between payroll calculations and payment processing
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

// Convert from payroll module's PayrollCalculation to payment record
PayrollRecordModel fromPayrollCalculation(String payPeriodId, dynamic calculation) {
  return PayrollRecordModel(
    id: calculation.id ?? '',
    payPeriodId: payPeriodId,
    workerId: calculation.workerId ?? '',
    workerName: calculation.workerName ?? '',
    grossSalary: calculation.grossSalary ?? 0.0,
    netSalary: calculation.netPay ?? 0.0,
    taxAmount: calculation.taxBreakdown.paye ?? 0.0,
    status: 'completed',
    createdAt: DateTime.now(),
  );
}