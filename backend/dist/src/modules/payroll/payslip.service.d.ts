import { PayrollRecord } from './entities/payroll-record.entity';
export declare class PayslipService {
    generatePayslip(record: PayrollRecord): Promise<Buffer>;
    private addCurrencyRow;
}
