import { PayrollService } from './payroll.service';
import { WorkersService } from '../workers/workers.service';

describe('Legacy payroll review ordering', () => {
  it.each(['getDraftPayroll', 'getPeriodRecords'] as const)(
    '%s matches the worker picker order without changing amounts',
    async (method) => {
      const workerFind = jest.fn().mockResolvedValue([]);
      const picker = Object.assign(Object.create(WorkersService.prototype), {
        workersRepository: { find: workerFind },
      }) as WorkersService;
      await picker.findAll('customer');
      const amounts = [10000, 10000, 12000, 18999.99, 18150];
      const records = amounts.map((amount, index) => ({
        id: `record-${index}`,
        workerId: `worker-${index}`,
        worker: { name: `Worker ${index}`, paymentMethod: 'CASH' },
        netSalary: String(amount),
        status: method === 'getDraftPayroll' ? 'draft' : 'finalized',
      }));
      const find = jest.fn().mockResolvedValue(records);
      const service = Object.assign(Object.create(PayrollService.prototype), {
        payrollRepository: { find },
      }) as PayrollService;
      const result = await service[method]('customer', 'period');
      expect(find.mock.calls[0][0]).toEqual({
        where: {
          userId: 'customer',
          payPeriodId: 'period',
          ...(method === 'getDraftPayroll' ? { status: 'draft' } : {}),
        },
        relations: ['worker'],
        order: { worker: workerFind.mock.calls[0][0].order },
      });
      expect(workerFind.mock.calls[0][0].order).toEqual({
        createdAt: 'DESC',
        id: 'DESC',
      });
      expect(result.map((row) => [row.workerId, row.netPay])).toEqual(
        records.map((row, index) => [row.workerId, amounts[index]]),
      );
    },
  );
});
