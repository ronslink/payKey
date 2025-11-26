import { TaxPaymentsService } from '../services/tax-payments.service';
import { CreateTaxPaymentDto, MonthlyTaxSummaryDto } from '../dto/tax-payment.dto';
import { TaxPayment, PaymentStatus } from '../entities/tax-payment.entity';
export declare class TaxPaymentsController {
    private readonly taxPaymentsService;
    constructor(taxPaymentsService: TaxPaymentsService);
    getMonthlySummary(req: any, year: string, month: string): Promise<MonthlyTaxSummaryDto>;
    recordPayment(req: any, dto: CreateTaxPaymentDto): Promise<TaxPayment>;
    getPaymentHistory(req: any): Promise<TaxPayment[]>;
    getPendingPayments(req: any): Promise<TaxPayment[]>;
    updatePaymentStatus(req: any, id: string, status: PaymentStatus): Promise<TaxPayment>;
    getPaymentInstructions(): Promise<any>;
}
