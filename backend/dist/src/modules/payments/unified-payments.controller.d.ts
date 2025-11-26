import { Repository } from 'typeorm';
import { StripeService } from './stripe.service';
import { MpesaService } from './mpesa.service';
import { Transaction } from './entities/transaction.entity';
import { Subscription, SubscriptionStatus, SubscriptionTier } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import { TaxType } from '../tax-config/entities/tax-config.entity';
interface AuthenticatedRequest {
    user: {
        userId: string;
        email: string;
        name?: string;
    };
}
interface PaymentMethodStatus {
    mpesa: {
        status: 'connected' | 'disconnected';
        balance: number;
    };
    stripe: {
        status: 'connected' | 'not_configured';
        accountConnected: boolean;
    };
}
interface SubscriptionInfo {
    currentPlan: SubscriptionTier;
    nextBilling: Date | null;
    amount: number;
}
interface TaxPaymentInfo {
    totalDue: number;
    nextDeadline: string;
    pendingPayments: number;
}
interface PaymentDashboardData {
    overview: {
        totalTransactions: number;
        totalAmount: number;
        successfulTransactions: number;
        pendingTransactions: number;
        failedTransactions: number;
        subscriptionsActive: number;
        taxPaymentsPending: number;
    };
    recentTransactions: Transaction[];
    paymentMethods: PaymentMethodStatus;
    subscription: SubscriptionInfo;
    taxPayments: TaxPaymentInfo;
}
interface CreateSubscriptionDto {
    planId: string;
    paymentMethod: 'stripe';
}
interface MpesaTopupDto {
    phoneNumber: string;
    amount: number;
}
interface RecordTaxPaymentDto {
    taxType: TaxType;
    amount: number;
    paymentDate?: string;
    reference: string;
}
export declare class UnifiedPaymentsController {
    private readonly stripeService;
    private readonly mpesaService;
    private readonly taxPaymentsService;
    private readonly transactionRepository;
    private readonly subscriptionRepository;
    private readonly subscriptionPaymentRepository;
    private static readonly DEFAULT_STRIPE_ACCOUNT;
    constructor(stripeService: StripeService, mpesaService: MpesaService, taxPaymentsService: TaxPaymentsService, transactionRepository: Repository<Transaction>, subscriptionRepository: Repository<Subscription>, subscriptionPaymentRepository: Repository<SubscriptionPayment>);
    getDashboard(req: AuthenticatedRequest): Promise<PaymentDashboardData>;
    createSubscription(req: AuthenticatedRequest, body: CreateSubscriptionDto): Promise<{
        checkoutUrl: string;
    }>;
    cancelSubscription(req: AuthenticatedRequest, subscriptionId: string): Promise<{
        message: string;
    }>;
    initiateMpesaTopup(req: AuthenticatedRequest, body: MpesaTopupDto): Promise<{
        success: boolean;
        checkoutRequestId: string;
        message: string;
    }>;
    recordTaxPayment(req: AuthenticatedRequest, body: RecordTaxPaymentDto): Promise<{
        success: boolean;
        paymentId: string;
        message: string;
    }>;
    getTaxPaymentSummary(req: AuthenticatedRequest): Promise<import("../tax-payments/dto/tax-payment.dto").MonthlyTaxSummaryDto>;
    getPaymentMethods(req: AuthenticatedRequest): Promise<{
        stripe: {
            configured: boolean;
            accountId: string;
            chargesEnabled: boolean;
            payoutsEnabled: boolean;
        };
        mpesa: {
            configured: boolean;
            shortcode: string;
        };
        subscription: {
            active: boolean;
            tier: SubscriptionTier | undefined;
            status: SubscriptionStatus | undefined;
        };
    }>;
    private getTransactionStats;
    private getRecentTransactions;
    private getActiveSubscriptionCount;
    private getActiveSubscription;
    private countPendingTaxPayments;
    private buildPaymentMethodStatus;
    private buildSubscriptionInfo;
    private throwBadRequest;
}
export {};
