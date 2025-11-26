export interface WorkerPayrollResult {
    workerId: string;
    workerName: string;
    success: boolean;
    grossSalary?: number;
    netPay?: number;
    transactionId?: string;
    error?: string;
}
export interface BatchPayrollResult {
    totalWorkers: number;
    successCount: number;
    failureCount: number;
    totalGross: number;
    totalNet: number;
    results: WorkerPayrollResult[];
    processedAt: Date;
}
