import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { TaxesService } from '../taxes/taxes.service';
import { PayrollCalculation } from '../taxes/interfaces/tax.interface';
import { Transaction } from './entities/transaction.entity';
import { TimeTrackingService } from '../time-tracking/time-tracking.service';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { MpesaService } from './mpesa.service';
export declare class PayrollService {
    private workerRepository;
    private transactionRepository;
    private payPeriodRepository;
    private taxSubmissionRepository;
    private taxesService;
    private timeTrackingService;
    private mpesaService;
    constructor(workerRepository: Repository<Worker>, transactionRepository: Repository<Transaction>, payPeriodRepository: Repository<PayPeriod>, taxSubmissionRepository: Repository<TaxSubmission>, taxesService: TaxesService, timeTrackingService: TimeTrackingService, mpesaService: MpesaService);
    private calculateWorkerPayroll;
    calculatePayroll(workerIds: string[], userId: string, startDate?: Date, endDate?: Date): Promise<PayrollCalculation[]>;
    createPayPeriod(userId: string, year: number, month: number): Promise<PayPeriod>;
    processPayroll(userId: string, workerIds: string[], payPeriodId: string): Promise<any>;
}
