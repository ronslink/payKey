import { PayPeriodStatus } from '../entities/pay-period.entity';
export declare class UpdatePayPeriodDto {
    name?: string;
    startDate?: string;
    endDate?: string;
    payDate?: string;
    status?: PayPeriodStatus;
    approvedBy?: string;
    approvedAt?: Date;
}
