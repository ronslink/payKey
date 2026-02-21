import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { IntaSendService } from '../payments/intasend.service';
import { StripeService } from '../payments/stripe.service';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
  PaymentMethodType,
} from '../payments/entities/transaction.entity';

@Controller('api/admin/refunds')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminRefundsController {
  constructor(
    @InjectRepository(Transaction)
    private readonly transactionRepo: Repository<Transaction>,
    private readonly intaSendService: IntaSendService,
    private readonly stripeService: StripeService,
  ) {}

  @Post()
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async initiateRefund(
    @Request() req: any,
    @Body()
    body: {
      transactionId: string;
      amount?: number; // Optional partial refund; defaults to full amount
      reason: string;
    },
  ) {
    const { transactionId, reason } = body;

    const original = await this.transactionRepo.findOne({
      where: { id: transactionId },
      relations: ['user'],
    });

    if (!original) throw new NotFoundException('Transaction not found');

    if (original.status !== TransactionStatus.SUCCESS) {
      throw new BadRequestException(
        `Cannot refund a transaction with status: ${original.status}`,
      );
    }

    const refundAmount = body.amount ?? Number(original.amount);

    if (refundAmount <= 0 || refundAmount > Number(original.amount)) {
      throw new BadRequestException('Invalid refund amount');
    }

    let providerResponse: any;

    // Route to correct payment provider
    if (
      original.paymentMethod === PaymentMethodType.STRIPE ||
      original.provider === 'stripe'
    ) {
      // Stripe refund via payment intent ref
      providerResponse = await this.stripeService.createRefund(
        original.providerRef,
        refundAmount,
      );
    } else {
      // IntaSend refund via B2C payout
      const phone = original.recipientPhone || original.user?.mpesaPhone;
      if (!phone) {
        throw new BadRequestException(
          'Cannot determine refund recipient phone number',
        );
      }

      providerResponse = await this.intaSendService.initiateRefund(
        phone,
        refundAmount,
        original.providerRef || transactionId,
        reason,
        original.user?.intasendWalletId,
      );
    }

    // Record the refund as a new transaction
    const refundTransaction = this.transactionRepo.create({
      userId: original.userId,
      amount: -refundAmount, // Negative to represent outflow
      currency: original.currency,
      type: TransactionType.REFUND,
      status: TransactionStatus.PENDING,
      providerRef: providerResponse?.tracking_id || providerResponse?.id,
      provider: original.provider,
      paymentMethod: original.paymentMethod,
      recipientPhone: original.recipientPhone,
      metadata: {
        originalTransactionId: transactionId,
        reason,
        initiatedBy: req.user.id,
        providerResponse,
      },
    });

    await this.transactionRepo.save(refundTransaction);

    return {
      message: 'Refund initiated successfully',
      refundTransactionId: refundTransaction.id,
      amount: refundAmount,
      currency: original.currency,
      providerResponse,
    };
  }
}
