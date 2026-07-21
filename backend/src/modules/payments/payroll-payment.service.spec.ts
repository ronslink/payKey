import { ConfigService } from '@nestjs/config';
import { PayrollPaymentService } from './payroll-payment.service';
import { PaymentMethod } from '../workers/entities/worker.entity';

describe('PayrollPaymentService fee estimates', () => {
  const createService = (config: Record<string, string | number> = {}) => {
    const configService = {
      get: jest.fn((key: string) => config[key]),
    } as unknown as ConfigService;

    return new PayrollPaymentService(
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      configService,
      {} as never,
    );
  };

  it('uses the public flat M-Pesa payout fee by default', () => {
    const service = createService();

    expect(service.estimatePayoutFee(50000, PaymentMethod.MPESA)).toBe(100);
  });

  it('accounts for every M-Pesa chunk when a payout exceeds the limit', () => {
    const service = createService({ MPESA_LIMIT: 250000 });

    expect(service.estimatePayoutFee(250001, PaymentMethod.MPESA)).toBe(200);
  });

  it.each([
    [10000, 100],
    [10001, 150],
    [50001, 200],
    [100001, 400],
    [500001, 500],
  ])('uses the public PesaLink band for KES %s', (amount, fee) => {
    const service = createService();

    expect(service.estimatePayoutFee(amount, PaymentMethod.BANK)).toBe(fee);
  });

  it('supports signed-contract fee overrides', () => {
    const service = createService({
      INTASEND_MPESA_PAYOUT_FEE_FLAT: 50,
      INTASEND_BANK_PAYOUT_FEE_FLAT: 75,
    });

    expect(service.estimatePayoutFee(50000, PaymentMethod.MPESA)).toBe(50);
    expect(service.estimatePayoutFee(50000, PaymentMethod.BANK)).toBe(75);
  });

  it('does not estimate provider fees for cash payments', () => {
    const service = createService();

    expect(service.estimatePayoutFee(50000, PaymentMethod.CASH)).toBe(0);
  });
});
