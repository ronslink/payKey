import { MpesaService } from './mpesa.service';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { Repository } from 'typeorm';
import { Transaction } from './entities/transaction.entity';
interface MpesaCallbackData {
    Body: {
        stkCallback: {
            MerchantRequestID: string;
            CheckoutRequestID: string;
            ResultCode: number;
            ResultDesc: string;
            CallbackMetadata?: {
                Item: Array<{
                    Name: string;
                    Value: string | number;
                }>;
            };
        };
    };
}
interface MpesaB2CCallbackData {
    Result: {
        ResultType: number;
        ResultCode: number;
        ResultDesc: string;
        OriginatorConversationID: string;
        ConversationID: string;
        TransactionID: string;
        ResultParameters: {
            ResultParameter: Array<{
                Key: string;
                Value: string | number;
            }>;
        };
        ReferenceData: {
            ReferenceItem: Array<{
                Key: string;
                Value: string;
            }>;
        };
    };
}
export declare class PaymentsController {
    private mpesaService;
    private transactionsRepository;
    constructor(mpesaService: MpesaService, transactionsRepository: Repository<Transaction>);
    handleStkCallback(callbackData: MpesaCallbackData): Promise<{
        ResultCode: number;
        ResultDesc: string;
    }>;
    handleB2CCallback(callbackData: MpesaB2CCallbackData): Promise<{
        ResultCode: number;
        ResultDesc: string;
    }>;
    handleB2CTimeout(timeoutData: unknown): {
        ResultCode: number;
        ResultDesc: string;
    };
    initiateStkPush(req: AuthenticatedRequest, body: {
        phoneNumber: string;
        amount: number;
    }): Promise<any>;
    sendB2CPayment(req: AuthenticatedRequest, body: {
        transactionId: string;
        phoneNumber: string;
        amount: number;
        remarks: string;
    }): Promise<any>;
}
export {};
