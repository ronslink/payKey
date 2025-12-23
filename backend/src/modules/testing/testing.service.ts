import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { TaxPayment } from '../tax-payments/entities/tax-payment.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class TestingService {
  constructor(
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(TaxSubmission)
    private taxSubmissionRepository: Repository<TaxSubmission>,
    @InjectRepository(TaxPayment)
    private taxPaymentRepository: Repository<TaxPayment>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async resetPayrollForUser(email: string) {
    const user = await this.userRepository.findOne({ where: { email } });
    if (!user) {
      return { message: 'User not found' };
    }

    const userId = user.id;

    // 1. Delete Tax Payments
    await this.taxPaymentRepository.delete({ userId });

    // 2. Delete Tax Submissions
    await this.taxSubmissionRepository.delete({ userId });

    // 3. Delete Payroll Records
    // Need to find records first as they don't always have userId directly on them in some schemas,
    // but PayPeriods do. However, checking schema suggests cascade might handle it if I delete PayPeriods.
    // But to be safe and thorough:

    // Find pay periods to get IDs
    const payPeriods = await this.payPeriodRepository.find({
      where: { userId },
    });
    const payPeriodIds = payPeriods.map((pp) => pp.id);

    if (payPeriodIds.length > 0) {
      // Delete records linked to these periods
      await this.payrollRecordRepository
        .createQueryBuilder()
        .delete()
        .where('payPeriodId IN (:...ids)', { ids: payPeriodIds })
        .execute();
    }

    // 4. Delete Pay Periods
    await this.payPeriodRepository.delete({ userId });

    return { message: `Payroll records reset for user ${email}` };
  }
}
