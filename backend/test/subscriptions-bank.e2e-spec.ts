import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { SubscriptionPlan } from './types/test-types';
import { IntaSendService } from '../src/modules/payments/intasend.service';

/**
 * Bank Subscription E2E Tests
 *
 * Verifies:
 * 1. User can save bank details to profile.
 * 2. User can initiate a Bank Subscription (IntaSend PesaLink).
 */
describe('Bank Subscription Flow E2E', () => {
    let app: INestApplication;
    let helpers: TestHelpers;
    let authToken: string;
    let testUser: any;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        })
            .overrideProvider(IntaSendService)
            .useValue({
                createCheckoutUrl: jest.fn().mockResolvedValue({
                    url: 'https://sandbox.intasend.com/checkout/mock-url-123',
                    id: 'mock-checkout-id',
                    signature: 'mock-signature',
                }),
                initiateStkPush: jest.fn().mockResolvedValue({
                    invoice: { invoice_id: 'mock-invoice-id' },
                    tracking_id: 'mock-tracking-id',
                }),
            })
            .compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        helpers = createTestHelpers(app);

        // Create a fresh user for this test
        testUser = await helpers.createTestUser({
            emailPrefix: 'bank-sub-test',
            firstName: 'BankTester',
            lastName: 'User',
            businessName: 'Bank Test Ltd',
        });

        authToken = testUser.token;
    });

    afterAll(async () => {
        if (app) {
            await app.close();
        }
    });

    describe('1. Bank Details Collection', () => {
        it('should allow saving bank details to profile', async () => {
            const bankDetails = {
                bankName: 'KCB Bank',
                bankAccount: '1234567890',
            };

            const res = await request(app.getHttpServer())
                .patch('/users/profile')
                .set('Authorization', `Bearer ${authToken}`)
                .send(bankDetails)
                .expect(200);

            expect(res.body).toHaveProperty('bankName', bankDetails.bankName);
            expect(res.body).toHaveProperty('bankAccount', bankDetails.bankAccount);
        });
    });

    describe('2. Bank Subscription Initiation', () => {
        let targetPlan: SubscriptionPlan;

        // Fetch a paid plan first
        it('should find a paid plan to subscribe to', async () => {
            const res = await request(app.getHttpServer())
                .get('/payments/subscriptions/plans') // Note: Using existing endpoint from other tests
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            const plans = res.body as SubscriptionPlan[];
            // Find a paid plan (e.g. BASIC or GOLD)
            targetPlan = plans.find((p) => p.price_usd > 0);

            expect(targetPlan).toBeDefined();
            console.log('Target Plan:', targetPlan.name, targetPlan.id);
        });

        it('should generate IntaSend Checkout URL for Bank Payment', async () => {
            if (!targetPlan) throw new Error('No paid plan found');

            const payload = {
                planId: targetPlan.id,
                paymentMethod: 'BANK',
                billingPeriod: 'monthly',
            };

            // Try /subscriptions/subscribe first (Standard Controller)
            // If fails, try /payments/subscriptions/subscribe (if proxied)
            // Based on code, Controller is @Controller('subscriptions')

            const res = await request(app.getHttpServer())
                .post('/subscriptions/subscribe')
                .set('Authorization', `Bearer ${authToken}`)
                .send(payload)
                .expect(201); // Standard NestJS POST returns 201

            // Verify Response structure
            expect(res.body.success).toBe(true);
            expect(res.body.message).toContain('Bank transfer checkout initiated');
            expect(res.body).toHaveProperty('checkoutUrl');
            expect(res.body).toHaveProperty('reference');
            // IntaSend URL usually contains 'intasend.com'
            expect(res.body.checkoutUrl).toContain('intasend');

            console.log('Bank Checkout URL:', res.body.checkoutUrl);
        });
    });
});
