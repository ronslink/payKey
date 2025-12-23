import {
  Controller,
  Post,
  Body,
  Headers,
  UseGuards,
  Request,
} from '@nestjs/common';
import { MpesaService } from './mpesa.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Transaction, TransactionStatus } from './entities/transaction.entity';
import { User } from '../users/entities/user.entity';
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import {
  PayPeriod,
  PayPeriodStatus,
} from '../payroll/entities/pay-period.entity';

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

@Controller('payments')
export class PaymentsController {
  constructor(
    private mpesaService: MpesaService,
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
  ) {}

  @Post('callback')
  async handleStkCallback(@Body() callbackData: MpesaCallbackData) {
    const { stkCallback } = callbackData.Body;

    // Handle STK push callback
    if (stkCallback.ResultCode === 0) {
      // Payment successful
      console.log('Payment successful:', stkCallback);

      // Extract transaction details from callback metadata
      if (stkCallback.CallbackMetadata) {
        const metadata = stkCallback.CallbackMetadata.Item.reduce(
          (acc, item) => {
            acc[item.Name] = item.Value;
            return acc;
          },
          {} as Record<string, string | number>,
        );

        console.log('Payment metadata:', metadata);

        // Update transaction status in database
        const transaction = await this.transactionsRepository.findOne({
          where: { providerRef: stkCallback.MerchantRequestID },
        });

        if (transaction) {
          transaction.status = 'SUCCESS' as any;
          transaction.metadata = metadata;
          await this.transactionsRepository.save(transaction);

          // Credit user's wallet balance with the topup amount
          await this.usersRepository.increment(
            { id: transaction.userId },
            'walletBalance',
            transaction.amount,
          );
          console.log(
            `Credited wallet for user ${transaction.userId}: +${transaction.amount}`,
          );
        }
      }
    } else {
      // Payment failed
      console.log('Payment failed:', stkCallback.ResultDesc);

      // Update transaction status to failed
      const transaction = await this.transactionsRepository.findOne({
        where: { providerRef: stkCallback.MerchantRequestID },
      });

      if (transaction) {
        transaction.status = 'FAILED' as any;
        transaction.metadata = { error: stkCallback.ResultDesc };
        await this.transactionsRepository.save(transaction);
      }
    }

    return { ResultCode: 0, ResultDesc: 'Success' };
  }

  @Post('b2c/result')
  async handleB2CCallback(@Body() callbackData: MpesaB2CCallbackData) {
    const { Result } = callbackData;

    // Handle B2C payment result
    if (Result.ResultCode === 0) {
      // B2C payment successful
      console.log('B2C payment successful:', Result);

      // Extract transaction details
      const transactionId = Result.TransactionID;
      const conversationId = Result.ConversationID;

      // Update transaction status in database
      const transaction = await this.transactionsRepository.findOne({
        where: { providerRef: conversationId },
      });

      if (transaction) {
        transaction.status = 'SUCCESS' as any;
        transaction.metadata = {
          transactionId,
          conversationId,
          resultCode: Result.ResultCode,
        };
        await this.transactionsRepository.save(transaction);

        // Deduct from user's wallet balance after successful B2C payment
        await this.usersRepository.decrement(
          { id: transaction.userId },
          'walletBalance',
          transaction.amount,
        );
        console.log(
          `Debited wallet for user ${transaction.userId}: -${transaction.amount}`,
        );

        // Update linked PayrollRecord if this was a salary payout
        const payrollRecordId = transaction.metadata?.payrollRecordId;
        if (payrollRecordId) {
          await this.payrollRecordRepository.update(payrollRecordId, {
            status: PayrollStatus.FINALIZED,
            paymentStatus: 'paid',
            paymentDate: new Date(),
          });
          console.log(
            `Updated PayrollRecord ${payrollRecordId} to FINALIZED/paid`,
          );
        }

        // Check if all payments for this pay period are complete
        const payPeriodId = transaction.metadata?.payPeriodId;
        if (payPeriodId) {
          // Count pending payments for this pay period
          const pendingCount = await this.transactionsRepository.count({
            where: {
              userId: transaction.userId,
              type: 'SALARY_PAYOUT' as any,
              status: TransactionStatus.PENDING,
            },
          });

          // If no pending payments, mark pay period as COMPLETED
          if (pendingCount === 0) {
            await this.payPeriodRepository.update(payPeriodId, {
              status: PayPeriodStatus.COMPLETED,
            });
            console.log(
              `PayPeriod ${payPeriodId} marked as COMPLETED (all payments successful)`,
            );
          }
        }
      }
    } else {
      // B2C payment failed
      console.log('B2C payment failed:', Result.ResultDesc);

      // Update transaction status to failed
      const transaction = await this.transactionsRepository.findOne({
        where: { providerRef: Result.ConversationID },
      });

      if (transaction) {
        transaction.status = 'FAILED' as any;
        transaction.metadata = {
          error: Result.ResultDesc,
          conversationId: Result.ConversationID,
        };
        await this.transactionsRepository.save(transaction);
      }
    }

    return { ResultCode: 0, ResultDesc: 'Success' };
  }

  @Post('b2c/timeout')
  handleB2CTimeout(@Body() timeoutData: unknown) {
    console.log('B2C payment timeout:', timeoutData);
    // TODO: Handle timeout - mark transaction for retry or investigation
    return { ResultCode: 0, ResultDesc: 'Success' };
  }

  @Post('initiate-stk')
  @UseGuards(JwtAuthGuard)
  async initiateStkPush(
    @Request() req: AuthenticatedRequest,
    @Body() body: { phoneNumber: string; amount: number },
  ) {
    return this.mpesaService.initiateStkPush(
      req.user.userId,
      body.phoneNumber,
      body.amount,
    );
  }

  @Post('send-b2c')
  @UseGuards(JwtAuthGuard)
  async sendB2CPayment(
    @Request() req: AuthenticatedRequest,
    @Body()
    body: {
      transactionId: string;
      phoneNumber: string;
      amount: number;
      remarks: string;
    },
  ) {
    return this.mpesaService.sendB2C(
      body.transactionId,
      body.phoneNumber,
      body.amount,
      body.remarks,
    );
  }

  /**
   * DEV ONLY: Manually top up wallet balance for testing.
   * This bypasses M-Pesa and directly credits the user's wallet.
   */
  @Post('dev/topup')
  @UseGuards(JwtAuthGuard)
  async devTopup(
    @Request() req: AuthenticatedRequest,
    @Body() body: { amount: number },
  ) {
    // Only allow in development mode
    if (process.env.NODE_ENV === 'production') {
      throw new Error('This endpoint is only available in development mode');
    }

    const result = await this.usersRepository.increment(
      { id: req.user.userId },
      'walletBalance',
      body.amount,
    );

    // Get updated balance
    const user = await this.usersRepository.findOne({
      where: { id: req.user.userId },
      select: ['id', 'walletBalance'],
    });

    return {
      success: true,
      message: `DEV: Topped up wallet by KES ${body.amount}`,
      newBalance: user?.walletBalance ?? 0,
    };
  }
}
