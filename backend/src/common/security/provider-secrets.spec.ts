import { redactProviderSecrets } from './provider-secrets';
import { TransactionsController } from '../../modules/transactions/transactions.controller';
import { UnifiedPaymentsController } from '../../modules/payments/unified-payments.controller';
import { ReportsService } from '../../modules/reports/reports.service';

describe('provider authentication secret redaction', () => {
  const event = {
    invoice_id: 'invoice-1',
    state: 'COMPLETE',
    challenge: 'private-challenge',
    nested: {
      headers: {
        'X-Intasend-Signature': 'private-signature',
        Authorization: 'private-authorization',
      },
      list: [{ webhook_secret: 'private-secret', amount: 100 }],
      credentials: { key: 'private-key' },
    },
  };
  const metadata = { workerName: 'Employee', webhookEvent: event };
  const transaction = {
    id: 'transaction-1',
    amount: 100,
    createdAt: new Date('2026-09-18'),
    metadata,
  };

  const expectSafe = (value: unknown) => {
    expect(JSON.stringify(value)).not.toContain('private-');
    expect(JSON.stringify(value)).toContain('invoice-1');
    expect(JSON.stringify(value)).toContain('Employee');
  };

  it('removes nested authentication fields without mutating input or dates', () => {
    const output = redactProviderSecrets(transaction);
    expectSafe(output);
    expect(output.createdAt).toEqual(transaction.createdAt);
    expect(output.metadata.webhookEvent.state).toBe('COMPLETE');
    expect(transaction.metadata.webhookEvent.challenge).toBe(
      'private-challenge',
    );
  });

  it('redacts historical JSON strings and JSON encoded nested fields', () => {
    expectSafe(redactProviderSecrets(JSON.stringify(metadata)));
    const encoded = {
      workerName: 'Employee',
      webhookEvent: JSON.stringify(event),
    };
    expectSafe(redactProviderSecrets(encoded));
    expect(redactProviderSecrets('{"challenge":"private-challenge"')).toBe(
      '[redacted]',
    );
  });

  it('removes casing and separator variants of secret fields', () => {
    const output = redactProviderSecrets({
      INTASEND_CHALLENGE: 'private-challenge',
      client_secret: 'private-client-secret',
      accessToken: 'private-access-token',
      password: 'private-password',
      'X-API-Key': 'private-api-key',
      'Set-Cookie': 'private-cookie',
      status: 'SUCCESS',
    });
    expect(output).toEqual({ status: 'SUCCESS' });
  });

  it('bounds recursive payloads', () => {
    const circular: Record<string, unknown> = {};
    circular.child = circular;
    expect(() => JSON.stringify(redactProviderSecrets(circular))).not.toThrow();
  });

  it.each([metadata, JSON.stringify(metadata)])(
    'redacts both customer transaction endpoints',
    async (historicalMetadata) => {
      const record = { ...transaction, metadata: historicalMetadata };
      const query = {
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[record], 1]),
      };
      const repository = {
        createQueryBuilder: () => query,
        findOne: jest.fn().mockResolvedValue(record),
      };
      const controller = new TransactionsController(repository as any);
      const req = { user: { userId: 'employer-a' } };
      const list = await controller.getTransactions(req);
      const detail = await controller.getTransaction(req, record.id);
      expectSafe(list);
      expectSafe(detail);
      expect(query.where).toHaveBeenCalledWith('transaction.userId = :userId', {
        userId: 'employer-a',
      });
      expect(repository.findOne).toHaveBeenCalledWith({
        where: { id: record.id, userId: 'employer-a' },
      });
    },
  );

  it('redacts the unified payments dashboard', async () => {
    const query = {
      select: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      setParameters: jest.fn().mockReturnThis(),
      getRawOne: jest.fn().mockResolvedValue({}),
    };
    const controller = new UnifiedPaymentsController(
      {} as any,
      {
        generateMonthlySummary: jest.fn().mockResolvedValue({
          taxes: [],
          totalDue: 0,
          totalPaid: 0,
          paymentInstructions: { deadline: '2026-10-09' },
        }),
      } as any,
      {
        find: jest.fn().mockResolvedValue([transaction]),
        createQueryBuilder: () => query,
      } as any,
      {
        count: jest.fn().mockResolvedValue(0),
        findOne: jest.fn().mockResolvedValue(null),
      } as any,
      {} as any,
      {} as any,
      {} as any,
    );
    const output = await controller.getDashboard({
      user: { userId: 'employer-a', email: 'example@example.com' },
    });
    expectSafe(output.recentTransactions);
  });

  it('redacts monthly report transaction metadata', async () => {
    const service = new ReportsService(
      {} as any,
      { find: jest.fn().mockResolvedValue([transaction]) } as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );
    expectSafe(await service.getMonthlyPayrollReport('employer-a', 2026, 9));
  });
});
