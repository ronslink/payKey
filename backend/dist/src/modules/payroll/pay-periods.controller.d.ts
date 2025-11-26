import { PayPeriodsService } from './pay-periods.service';
import { CreatePayPeriodDto } from './dto/create-pay-period.dto';
import { UpdatePayPeriodDto } from './dto/update-pay-period.dto';
import { PayPeriodStatus, PayPeriodFrequency } from './entities/pay-period.entity';
export declare class PayPeriodsController {
    private readonly payPeriodsService;
    constructor(payPeriodsService: PayPeriodsService);
    create(createPayPeriodDto: CreatePayPeriodDto): Promise<import("./entities/pay-period.entity").PayPeriod>;
    findAll(page?: string, limit?: string, status?: PayPeriodStatus, frequency?: string): Promise<{
        data: import("./entities/pay-period.entity").PayPeriod[];
        total: number;
        page: number;
        limit: number;
    }>;
    findOne(id: string): Promise<import("./entities/pay-period.entity").PayPeriod>;
    update(id: string, updatePayPeriodDto: UpdatePayPeriodDto): Promise<import("./entities/pay-period.entity").PayPeriod>;
    remove(id: string): Promise<void>;
    activate(id: string): Promise<import("./entities/pay-period.entity").PayPeriod>;
    process(id: string): Promise<import("./entities/pay-period.entity").PayPeriod>;
    complete(id: string): Promise<import("./entities/pay-period.entity").PayPeriod>;
    close(id: string): Promise<import("./entities/pay-period.entity").PayPeriod>;
    getStatistics(id: string): Promise<any>;
    generatePayPeriods(body: {
        userId: string;
        frequency: PayPeriodFrequency;
        startDate: string;
        endDate: string;
    }): Promise<import("./entities/pay-period.entity").PayPeriod[]>;
}
