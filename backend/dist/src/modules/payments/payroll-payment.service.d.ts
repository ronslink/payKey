import { Repository } from 'typeorm';
import { Transaction } from './entities/transaction.entity';
import { MpesaService } from './mpesa.service';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
export declare class PayrollPaymentService {
    private transactionRepository;
    private mpesaService;
    private payrollRecordRepository;
    private readonly logger;
    constructor(transactionRepository: Repository<Transaction>, mpesaService: MpesaService, payrollRecordRepository: Repository<PayrollRecord>);
    processPayouts(payrollRecords: PayrollRecord[]): Promise<{
        successCount: number;
        failureCount: number;
        results: any[];
    }>;
}
