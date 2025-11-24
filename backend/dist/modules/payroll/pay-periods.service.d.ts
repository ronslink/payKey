import { Repository } from 'typeorm';
import { PayPeriod, PayPeriodStatus } from './entities/pay-period.entity';
import { CreatePayPeriodDto } from './dto/create-pay-period.dto';
import { UpdatePayPeriodDto } from './dto/update-pay-period.dto';
import { PayrollRecord } from './entities/payroll-record.entity';
export declare class PayPeriodsService {
    private payPeriodRepository;
    private payrollRecordRepository;
    constructor(payPeriodRepository: Repository<PayPeriod>, payrollRecordRepository: Repository<PayrollRecord>);
    create(createPayPeriodDto: CreatePayPeriodDto): Promise<PayPeriod>;
    findAll(page?: number, limit?: number, status?: PayPeriodStatus, frequency?: string): Promise<{
        data: PayPeriod[];
        total: number;
        page: number;
        limit: number;
    }>;
    findOne(id: string): Promise<PayPeriod>;
    update(id: string, updatePayPeriodDto: UpdatePayPeriodDto): Promise<PayPeriod>;
    remove(id: string): Promise<void>;
    activate(id: string): Promise<PayPeriod>;
    process(id: string): Promise<PayPeriod>;
    complete(id: string): Promise<PayPeriod>;
    close(id: string): Promise<PayPeriod>;
    private validateStatusTransition;
    getPayPeriodStatistics(id: string): Promise<any>;
    generatePayPeriods(userId: string, frequency: string, startDate: Date, endDate: Date): Promise<PayPeriod[]>;
    private getStepDays;
    private generatePeriodName;
}
