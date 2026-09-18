import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import Stripe from 'stripe';
import request from 'supertest';
import { registerRequestBodyParsers } from '../../common/http/request-body';
import { PaymentsController } from './payments.controller';
import { SubscriptionPaymentsController } from './subscription-payments.controller';
import { StripeService } from './stripe.service';
import { IntaSendService } from './intasend.service';
import { NotificationsService } from '../notifications/notifications.service';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { Transaction } from './entities/transaction.entity';
import { User } from '../users/entities/user.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';

describe.each([PaymentsController, SubscriptionPaymentsController])(
  '%p signed Stripe webhook routes',
  (Controller) => {
    const secret = 'whsec_local_regression_only';
    const stripe = new Stripe('sk_test_local_regression_only');
    const payload =
      '{\n  "id": "evt_local", "type": "invoice.paid", "data": {"object": {"id": "in_local"}}\n}';
    const paths =
      Controller === PaymentsController
        ? ['/payments/stripe/webhook', '/payments/subscriptions/webhook']
        : ['/payments/subscriptions/webhook'];
    let app: INestApplication;
    let dispatch: jest.SpyInstance;

    beforeAll(async () => {
      const service = new StripeService(
        new ConfigService({
          STRIPE_SECRET_KEY: 'sk_test_local_regression_only',
          STRIPE_WEBHOOK_SECRET: secret,
        }),
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );
      dispatch = jest.spyOn(service, 'handleWebhook').mockResolvedValue();
      const module = await Test.createTestingModule({
        controllers: [Controller],
        providers: [
          { provide: StripeService, useValue: service },
          ...[DataSource, IntaSendService, NotificationsService].map(
            (provide) => ({ provide, useValue: {} }),
          ),
          ...[
            Subscription,
            SubscriptionPayment,
            Transaction,
            User,
            PayrollRecord,
            PayPeriod,
            DeviceToken,
          ].map((entity) => ({
            provide: getRepositoryToken(entity),
            useValue: {},
          })),
        ],
      }).compile();
      app = module.createNestApplication({ bodyParser: false });
      registerRequestBodyParsers(app);
      await app.init();
    });
    beforeEach(() => dispatch.mockClear());
    afterAll(async () => {
      await app?.close();
    });

    it.each(paths)(
      'dispatches a correctly signed, whitespace-preserved raw payload at %s',
      async (endpoint) => {
        const signature = stripe.webhooks.generateTestHeaderString({
          payload,
          secret,
        });
        await request(app.getHttpServer())
          .post(endpoint)
          .set('Content-Type', 'application/json')
          .set('stripe-signature', signature)
          .send(payload)
          .expect(201);
        expect(dispatch).toHaveBeenCalledTimes(1);
        expect(dispatch).toHaveBeenCalledWith(JSON.parse(payload));
      },
    );

    it.each(paths)(
      'rejects changed bytes, wrong secrets, old signatures, and unsigned callbacks at %s',
      async (endpoint) => {
        const valid = stripe.webhooks.generateTestHeaderString({
          payload,
          secret,
        });
        const invalid = stripe.webhooks.generateTestHeaderString({
          payload,
          secret: 'whsec_wrong_secret',
        });
        const expired = stripe.webhooks.generateTestHeaderString({
          payload,
          secret,
          timestamp: 1,
        });
        for (const [body, signature] of [
          [payload.replace('in_local', 'in_changed'), valid],
          [payload, invalid],
          [payload, expired],
          [payload, ''],
        ]) {
          const req = request(app.getHttpServer())
            .post(endpoint)
            .set('Content-Type', 'application/json');
          if (signature) req.set('stripe-signature', signature);
          await req.send(body).expect(401);
        }
        expect(dispatch).not.toHaveBeenCalled();
      },
    );
  },
);
