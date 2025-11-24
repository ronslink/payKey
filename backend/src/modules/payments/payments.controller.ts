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

@Controller('payments')
export class PaymentsController {
  constructor(
    private mpesaService: MpesaService,
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
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
}
