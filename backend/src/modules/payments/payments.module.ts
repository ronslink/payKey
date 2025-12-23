import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { PaymentsController } from './payments.controller';
import { UnifiedPaymentsController } from './unified-payments.controller';
import { SubscriptionPaymentsController } from './subscription-payments.controller';
import { MpesaService } from './mpesa.service';
import { StripeService } from './stripe.service';
import { PayrollPaymentService } from './payroll-payment.service';
import { PayrollService } from './payroll.service';
import { Transaction } from './entities/transaction.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { TaxesModule } from '../taxes/taxes.module';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { User } from '../users/entities/user.entity';
import { TimeTrackingModule } from '../time-tracking/time-tracking.module';
import { TaxPaymentsModule } from '../tax-payments/tax-payments.module';

import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Transaction,
      Worker,
      PayPeriod,
      PayrollRecord,
      TaxSubmission,
      Subscription,
      SubscriptionPayment,
      User,
    ]),
    TaxesModule,
    TimeTrackingModule,
    TaxPaymentsModule,
    HttpModule,
    ConfigModule,
  ],
  controllers: [
    PaymentsController,
    UnifiedPaymentsController,
    SubscriptionPaymentsController,
  ],
  providers: [
    MpesaService,
    StripeService,
    PayrollPaymentService,
    PayrollService,
  ],
  exports: [MpesaService, StripeService, PayrollPaymentService, PayrollService],
})
export class PaymentsModule {}
