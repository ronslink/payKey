import { Repository } from 'typeorm';
import { PayrollRecord } from './entities/payroll-record.entity';
export declare class PayrollRecordsController {
    private payrollRepository;
    constructor(payrollRepository: Repository<PayrollRecord>);
    getPayrollRecords(req: any): Promise<PayrollRecord[]>;
    updatePayrollStatus(req: any, id: string, body: {
        status: string;
        paymentDate?: string;
    }): Promise<import("typeorm").UpdateResult>;
    deletePayrollRecord(req: any, id: string): Promise<import("typeorm").DeleteResult>;
}
