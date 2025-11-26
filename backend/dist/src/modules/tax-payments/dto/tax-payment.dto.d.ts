import { TaxType } from '../../tax-config/entities/tax-config.entity';
import { PaymentMethod } from '../entities/tax-payment.entity';
export declare class CreateTaxPaymentDto {
    taxType: TaxType;
    paymentYear: number;
    paymentMonth: number;
    amount: number;
    paymentDate?: string;
    paymentMethod?: PaymentMethod;
    receiptNumber?: string;
    notes?: string;
}
export declare class TaxSummaryDto {
    taxType: TaxType;
    amount: number;
    status: string;
    dueDate: string;
}
export declare class MonthlyTaxSummaryDto {
    year: number;
    month: number;
    totalDue: number;
    totalPaid: number;
    taxes: TaxSummaryDto[];
    paymentInstructions: {
        mpesa: {
            paybill: string;
            accountNumber: string;
        };
        bank: string;
        deadline: string;
    };
}
