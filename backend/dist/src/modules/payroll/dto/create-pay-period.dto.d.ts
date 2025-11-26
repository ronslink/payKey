import { PayPeriodFrequency } from '../entities/pay-period.entity';
export declare class CreatePayPeriodDto {
    name: string;
    startDate: string;
    endDate: string;
    payDate?: string;
    frequency: PayPeriodFrequency;
    notes?: Record<string, any>;
    createdBy?: string;
}
