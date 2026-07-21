import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from './entities/subscription.entity';
import {
  PaymentMethod,
  PaymentStatus,
  SubscriptionPayment,
} from './entities/subscription-payment.entity';
import { SubscriptionProcessor } from './subscription.processor';
import { User } from '../users/entities/user.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { IntaSendService } from '../payments/intasend.service';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../payments/entities/transaction.entity';

describe('SubscriptionProcessor', () => {
  let processor: SubscriptionProcessor;
  let subscriptionRepository: {
    create: jest.Mock;
    findOne: jest.Mock;
    save: jest.Mock;
  };
  let paymentRepository: {
    create: jest.Mock;
    find: jest.Mock;
    save: jest.Mock;
  };
  let transactionRepository: {
    create: jest.Mock;
    save: jest.Mock;
  };
  let userRepository: {
    findOne: jest.Mock;
    decrement: jest.Mock;
    update: jest.Mock;
  };
  let deviceTokenRepository: {
    findOne: jest.Mock;
  };
  let intaSendService: {
    createCheckoutUrl: jest.Mock;
  };
  let notificationsService: {
    sendPaymentStatusNotification: jest.Mock;
    sendSubscriptionPaymentDueNotification: jest.Mock;
    sendNotification: jest.Mock;
  };

  beforeEach(async () => {
    subscriptionRepository = {
      create: jest.fn().mockImplementation((entity) => entity),
      findOne: jest.fn(),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };
    paymentRepository = {
      create: jest.fn().mockImplementation((entity) => entity),
      find: jest.fn().mockResolvedValue([]),
      save: jest
        .fn()
        .mockImplementation((entity) =>
          Promise.resolve({ ...entity, id: entity.id || 'payment-1' }),
        ),
    };
    transactionRepository = {
      create: jest.fn().mockImplementation((entity) => entity),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };
    userRepository = {
      findOne: jest.fn(),
      decrement: jest.fn(),
      update: jest.fn(),
    };
    deviceTokenRepository = {
      findOne: jest.fn().mockResolvedValue(null),
    };
    intaSendService = {
      createCheckoutUrl: jest.fn().mockResolvedValue({
        id: 'checkout-1',
        url: 'https://sandbox.intasend.com/checkout/renewal/express/',
      }),
    };
    notificationsService = {
      sendPaymentStatusNotification: jest.fn().mockResolvedValue({
        success: true,
      }),
      sendSubscriptionPaymentDueNotification: jest.fn().mockResolvedValue({
        success: true,
      }),
      sendNotification: jest.fn().mockResolvedValue({
        success: true,
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionProcessor,
        {
          provide: getRepositoryToken(Subscription),
          useValue: subscriptionRepository,
        },
        {
          provide: getRepositoryToken(SubscriptionPayment),
          useValue: paymentRepository,
        },
        {
          provide: getRepositoryToken(Transaction),
          useValue: transactionRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: userRepository,
        },
        {
          provide: getRepositoryToken(DeviceToken),
          useValue: deviceTokenRepository,
        },
        {
          provide: IntaSendService,
          useValue: intaSendService,
        },
        {
          provide: NotificationsService,
          useValue: notificationsService,
        },
      ],
    }).compile();

    processor = module.get(SubscriptionProcessor);
  });

  it('creates an IntaSend renewal checkout instead of deducting the payroll wallet', async () => {
    const dueDate = new Date('2026-05-14T00:00:00Z');
    const subscription = {
      id: 'subscription-1',
      userId: 'user-1',
      tier: SubscriptionTier.BASIC,
      status: SubscriptionStatus.ACTIVE,
      billingPeriod: 'monthly',
      startDate: new Date('2026-04-14T00:00:00Z'),
      endDate: dueDate,
      nextBillingDate: dueDate,
      notes: null,
    } as Subscription;
    const user = {
      id: 'user-1',
      email: 'renewal@example.com',
      firstName: 'Renewal',
      lastName: 'User',
      walletBalance: 999999,
    } as User;

    subscriptionRepository.findOne.mockResolvedValue(subscription);
    userRepository.findOne.mockResolvedValue(user);
    deviceTokenRepository.findOne.mockResolvedValue({
      token: 'fcm-renewal-token',
    });

    const result = await processor.process({
      id: 'job-1',
      name: 'renew-subscription',
      data: { subscriptionId: subscription.id },
    } as any);

    expect(result.status).toBe('awaiting_payment');
    expect(userRepository.decrement).not.toHaveBeenCalled();
    expect(userRepository.update).not.toHaveBeenCalled();
    expect(intaSendService.createCheckoutUrl).toHaveBeenCalledWith(
      1300,
      user.email,
      user.firstName,
      user.lastName,
      expect.stringMatching(/^SUB-RENEW-/),
      undefined,
      { method: 'PESALINK', comment: 'Paydome subscription renewal' },
    );
    expect(paymentRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        subscriptionId: subscription.id,
        userId: user.id,
        amount: 1300,
        status: PaymentStatus.PENDING,
        paymentMethod: PaymentMethod.BANK_TRANSFER,
        paymentProvider: 'INTASEND',
        metadata: expect.objectContaining({
          renewal: true,
          checkoutUrl: 'https://sandbox.intasend.com/checkout/renewal/express/',
        }),
      }),
    );
    expect(transactionRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: user.id,
        type: TransactionType.SUBSCRIPTION,
        status: TransactionStatus.PENDING,
        provider: 'INTASEND',
        metadata: expect.objectContaining({
          subscriptionPaymentId: 'payment-1',
          renewal: true,
        }),
      }),
    );
    expect(subscriptionRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        id: subscription.id,
        status: SubscriptionStatus.PAST_DUE,
        gracePeriodEndDate: expect.any(Date),
      }),
    );
    expect(notificationsService.sendNotification).toHaveBeenCalledWith(
      expect.objectContaining({
        recipientEmail: user.email,
        subject: 'PayDome subscription payment due',
        metadata: expect.objectContaining({
          type: 'SUBSCRIPTION_PAYMENT_DUE',
          checkoutUrl: 'https://sandbox.intasend.com/checkout/renewal/express/',
        }),
      }),
    );
    expect(
      notificationsService.sendSubscriptionPaymentDueNotification,
    ).toHaveBeenCalledWith(
      'fcm-renewal-token',
      1300,
      'https://sandbox.intasend.com/checkout/renewal/express/',
      expect.any(Date),
    );
  });

  it('does not create duplicate renewal checkouts while one is pending', async () => {
    const subscription = {
      id: 'subscription-1',
      userId: 'user-1',
      tier: SubscriptionTier.BASIC,
      status: SubscriptionStatus.PAST_DUE,
      billingPeriod: 'monthly',
      nextBillingDate: new Date('2026-05-14T00:00:00Z'),
    } as Subscription;

    subscriptionRepository.findOne.mockResolvedValue(subscription);
    userRepository.findOne.mockResolvedValue({
      id: 'user-1',
      email: 'renewal@example.com',
    });
    paymentRepository.find.mockResolvedValue([
      {
        id: 'existing-payment',
        metadata: {
          renewal: true,
          checkoutUrl: 'https://sandbox.intasend.com/checkout/existing/',
        },
      },
    ]);

    const result = await processor.process({
      id: 'job-1',
      name: 'renew-subscription',
      data: { subscriptionId: subscription.id },
    } as any);

    expect(result).toEqual({
      status: 'awaiting_payment',
      paymentId: 'existing-payment',
      checkoutUrl: 'https://sandbox.intasend.com/checkout/existing/',
    });
    expect(intaSendService.createCheckoutUrl).not.toHaveBeenCalled();
    expect(transactionRepository.save).not.toHaveBeenCalled();
  });

  it('downgrades at renewal date instead of creating a checkout when auto-renewal is disabled', async () => {
    const dueDate = new Date('2026-05-14T00:00:00Z');
    const subscription = {
      id: 'subscription-1',
      userId: 'user-1',
      tier: SubscriptionTier.BASIC,
      status: SubscriptionStatus.ACTIVE,
      billingPeriod: 'monthly',
      nextBillingDate: dueDate,
      autoRenewal: false,
      notes: null,
    } as Subscription;
    const user = {
      id: 'user-1',
      email: 'renewal@example.com',
    } as User;

    subscriptionRepository.findOne.mockResolvedValue(subscription);
    userRepository.findOne.mockResolvedValue(user);

    const result = await processor.process({
      id: 'job-1',
      name: 'renew-subscription',
      data: { subscriptionId: subscription.id },
    } as any);

    expect(result).toEqual({
      status: 'downgraded',
      reason: 'auto_renewal_disabled',
    });
    expect(intaSendService.createCheckoutUrl).not.toHaveBeenCalled();
    expect(transactionRepository.save).not.toHaveBeenCalled();
    expect(userRepository.update).toHaveBeenCalledWith(
      { id: user.id },
      { tier: 'FREE' },
    );
    expect(subscriptionRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        id: subscription.id,
        status: SubscriptionStatus.EXPIRED,
        nextBillingDate: null,
      }),
    );
    expect(paymentRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        subscriptionId: subscription.id,
        status: PaymentStatus.FAILED,
        metadata: expect.objectContaining({
          autoRenewalDisabled: true,
        }),
      }),
    );
  });

  it('downgrades to Free after the unpaid renewal grace period expires', async () => {
    const gracePeriodEndDate = new Date('2026-05-13T00:00:00Z');
    jest.useFakeTimers().setSystemTime(new Date('2026-05-14T00:00:00Z'));

    const subscription = {
      id: 'subscription-1',
      userId: 'user-1',
      tier: SubscriptionTier.BASIC,
      status: SubscriptionStatus.PAST_DUE,
      billingPeriod: 'monthly',
      nextBillingDate: new Date('2026-05-01T00:00:00Z'),
      gracePeriodEndDate,
      notes: null,
    } as Subscription;
    const user = {
      id: 'user-1',
      email: 'renewal@example.com',
    } as User;

    subscriptionRepository.findOne.mockResolvedValue(subscription);
    userRepository.findOne.mockResolvedValue(user);

    const result = await processor.process({
      id: 'job-1',
      name: 'renew-subscription',
      data: { subscriptionId: subscription.id },
    } as any);

    expect(result).toEqual({
      status: 'downgraded',
      reason: 'renewal_unpaid_after_grace',
    });
    expect(intaSendService.createCheckoutUrl).not.toHaveBeenCalled();
    expect(userRepository.update).toHaveBeenCalledWith(
      { id: user.id },
      { tier: 'FREE' },
    );
    expect(subscriptionRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        id: subscription.id,
        status: SubscriptionStatus.EXPIRED,
        nextBillingDate: null,
        gracePeriodEndDate: null,
      }),
    );
    expect(subscriptionRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: user.id,
        tier: SubscriptionTier.FREE,
        status: SubscriptionStatus.ACTIVE,
      }),
    );
    expect(paymentRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        subscriptionId: subscription.id,
        status: PaymentStatus.FAILED,
        metadata: expect.objectContaining({
          expiredAfterGrace: true,
        }),
      }),
    );

    jest.useRealTimers();
  });
});
