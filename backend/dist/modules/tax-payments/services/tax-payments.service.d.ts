import { Repository } from 'typeorm';
import { TaxPayment, PaymentStatus } from '../entities/tax-payment.entity';
import { TaxConfigService } from '../../tax-config/services/tax-config.service';
import { TaxesService } from '../../taxes/taxes.service';
import { CreateTaxPaymentDto, MonthlyTaxSummaryDto } from '../dto/tax-payment.dto';
export declare class TaxPaymentsService {
    private taxPaymentRepository;
    private taxConfigService;
    private taxesService;
    constructor(taxPaymentRepository: Repository<TaxPayment>, taxConfigService: TaxConfigService, taxesService: TaxesService);
    generateMonthlySummary(userId: string, year: number, month: number): Promise<MonthlyTaxSummaryDto>;
    private calculateTaxAmount;
    private calculateDueDate;
    recordPayment(userId: string, dto: CreateTaxPaymentDto): Promise<TaxPayment>;
    getPaymentHistory(userId: string): Promise<TaxPayment[]>;
    getPendingPayments(userId: string): Promise<TaxPayment[]>;
    updatePaymentStatus(id: string, userId: string, status: PaymentStatus): Promise<TaxPayment>;
}
