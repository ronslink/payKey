import { Subscription } from './subscription.entity';
export declare enum PaymentStatus {
    PENDING = "PENDING",
    COMPLETED = "COMPLETED",
    FAILED = "FAILED",
    REFUNDED = "REFUNDED"
}
export declare enum PaymentMethod {
    CREDIT_CARD = "Credit Card",
    BANK_TRANSFER = "Bank Transfer",
    PAYPAL = "PayPal",
    STRIPE = "stripe"
}
export declare class SubscriptionPayment {
    id: string;
    subscription: Subscription;
    subscriptionId: string;
    userId: string;
    amount: number;
    currency: string;
    status: PaymentStatus;
    paymentMethod: PaymentMethod | string;
    billingPeriod: string;
    periodStart: Date;
    periodEnd: Date;
    dueDate: Date;
    paidDate: Date;
    invoiceNumber: string;
    paymentProvider: string;
    transactionId: string;
    metadata: any;
    notes: string;
    createdAt: Date;
    updatedAt: Date;
}
