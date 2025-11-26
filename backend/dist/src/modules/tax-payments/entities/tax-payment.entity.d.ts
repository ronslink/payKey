import { User } from '../../users/entities/user.entity';
import { TaxType } from '../../tax-config/entities/tax-config.entity';
export declare enum PaymentStatus {
    PENDING = "PENDING",
    PAID = "PAID",
    OVERDUE = "OVERDUE"
}
export declare enum PaymentMethod {
    MPESA = "MPESA",
    BANK = "BANK"
}
export declare class TaxPayment {
    id: string;
    user: User;
    userId: string;
    taxType: TaxType;
    paymentYear: number;
    paymentMonth: number;
    amount: number;
    paymentDate: Date;
    paymentMethod: PaymentMethod;
    receiptNumber: string;
    status: PaymentStatus;
    notes: string;
    createdAt: Date;
    updatedAt: Date;
}
