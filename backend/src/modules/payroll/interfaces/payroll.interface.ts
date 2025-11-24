export interface PayrollPaymentResult {
  workerId: string;
  workerName: string;
  grossSalary: number;
  netPay: number;
  paymentStatus: 'SUCCESS' | 'FAILED' | 'PENDING';
  transactionId?: string;
  errorMessage?: string;
}

export interface BatchPayrollRequest {
  workerIds: string[];
  processDate: Date;
}

export interface BatchPayrollResult {
  batchId: string;
  totalWorkers: number;
  successfulPayments: number;
  failedPayments: number;
  results: PayrollPaymentResult[];
}
