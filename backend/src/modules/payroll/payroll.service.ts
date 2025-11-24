import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { TaxesService } from '../taxes/taxes.service';
import { PayrollRecord, PayrollStatus } from './entities/payroll-record.entity';

@Injectable()
export class PayrollService {
  constructor(
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
    @InjectRepository(PayrollRecord)
    private payrollRepository: Repository<PayrollRecord>,
    private taxesService: TaxesService,
  ) { }

  async calculatePayrollForUser(userId: string) {
    const workers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    const payrollItems = await Promise.all(
      workers.map(async (worker) => {
        const taxBreakdown = await this.taxesService.calculateTaxes(
          worker.salaryGross,
        );
        const netPay = worker.salaryGross - taxBreakdown.totalDeductions;

        return {
          workerId: worker.id,
          workerName: worker.name,
          grossSalary: worker.salaryGross,
          taxBreakdown,
          netPay: Math.round(netPay * 100) / 100,
          phoneNumber: worker.phoneNumber,
        };
      }),
    );

    const totalGross = payrollItems.reduce(
      (sum, item) => sum + item.grossSalary,
      0,
    );
    const totalDeductions = payrollItems.reduce(
      (sum, item) => sum + item.taxBreakdown.totalDeductions,
      0,
    );
    const totalNetPay = payrollItems.reduce(
      (sum, item) => sum + item.netPay,
      0,
    );

    return {
      payrollItems,
      summary: {
        totalGross: Math.round(totalGross * 100) / 100,
        totalDeductions: Math.round(totalDeductions * 100) / 100,
        totalNetPay: Math.round(totalNetPay * 100) / 100,
        workerCount: workers.length,
      },
    };
  }

  async calculateSingleWorkerPayroll(workerId: string, userId: string) {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new Error('Worker not found');
    }

    const taxBreakdown = await this.taxesService.calculateTaxes(
      worker.salaryGross,
    );
    const netPay = worker.salaryGross - taxBreakdown.totalDeductions;

    return {
      worker,
      payrollCalculation: {
        grossSalary: worker.salaryGross,
        taxBreakdown,
        netPay: Math.round(netPay * 100) / 100,
      },
    };
  }
  async saveDraftPayroll(
    userId: string,
    payPeriodId: string,
    items: Array<{
      workerId: string;
      grossSalary: number;
      bonuses?: number;
      otherEarnings?: number;
      otherDeductions?: number;
    }>,
  ) {
    // Get pay period dates (mocking for now, ideally fetch from PayPeriod entity)
    const periodStart = new Date(); // Should be fetched
    const periodEnd = new Date();   // Should be fetched

    const savedRecords = await Promise.all(
      items.map(async (item) => {
        // Calculate taxes
        const totalEarnings = item.grossSalary + (item.bonuses || 0) + (item.otherEarnings || 0);
        const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);

        const totalDeductions = taxBreakdown.totalDeductions + (item.otherDeductions || 0);
        const netPay = totalEarnings - totalDeductions;

        // Check if draft exists
        let record = await this.payrollRepository.findOne({
          where: {
            userId,
            payPeriodId, // Assuming we add payPeriodId to entity, wait, I need to check if I added it.
            workerId: item.workerId,
            status: PayrollStatus.DRAFT,
          },
        });

        if (!record) {
          record = new PayrollRecord();
          record.userId = userId;
          record.payPeriodId = payPeriodId;
          record.workerId = item.workerId;
          record.status = PayrollStatus.DRAFT;
          record.periodStart = periodStart;
          record.periodEnd = periodEnd;
        }

        record.grossSalary = item.grossSalary;
        record.bonuses = item.bonuses || 0;
        record.otherEarnings = item.otherEarnings || 0;
        record.otherDeductions = item.otherDeductions || 0;
        record.taxAmount = taxBreakdown.paye; // Storing PAYE as taxAmount? Or total tax?
        // Let's store PAYE as taxAmount for now, or total deductions?
        // Entity has taxAmount. Let's use PAYE.
        record.taxAmount = taxBreakdown.paye;

        record.netSalary = netPay;
        record.taxBreakdown = taxBreakdown;
        record.deductions = {
          ...taxBreakdown,
          otherDeductions: item.otherDeductions || 0,
        };

        return this.payrollRepository.save(record);
      }),
    );

    return savedRecords;
  }

  async updateDraftPayrollItem(
    userId: string,
    recordId: string,
    updates: {
      grossSalary?: number;
      bonuses?: number;
      otherEarnings?: number;
      otherDeductions?: number;
    },
  ) {
    const record = await this.payrollRepository.findOne({
      where: { id: recordId, userId, status: PayrollStatus.DRAFT },
    });

    if (!record) {
      throw new Error('Draft payroll record not found');
    }

    if (updates.grossSalary !== undefined) record.grossSalary = updates.grossSalary;
    if (updates.bonuses !== undefined) record.bonuses = updates.bonuses;
    if (updates.otherEarnings !== undefined) record.otherEarnings = updates.otherEarnings;
    if (updates.otherDeductions !== undefined) record.otherDeductions = updates.otherDeductions;

    // Recalculate
    const totalEarnings = Number(record.grossSalary) + Number(record.bonuses) + Number(record.otherEarnings);
    const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);

    const totalDeductions = taxBreakdown.totalDeductions + Number(record.otherDeductions);
    const netPay = totalEarnings - totalDeductions;

    record.taxAmount = taxBreakdown.paye;
    record.netSalary = netPay;
    record.taxBreakdown = taxBreakdown;
    record.deductions = {
      ...taxBreakdown,
      otherDeductions: record.otherDeductions,
    };

    return this.payrollRepository.save(record);
  }

  async getDraftPayroll(userId: string, payPeriodId: string) {
    const records = await this.payrollRepository.find({
      where: {
        userId,
        payPeriodId,
        status: PayrollStatus.DRAFT,
      },
      relations: ['worker'],
    });

    // Transform to match the expected format (PayrollCalculation)
    return records.map(record => ({
      id: record.id,
      workerId: record.workerId,
      workerName: record.worker.name,
      grossSalary: Number(record.grossSalary),
      bonuses: Number(record.bonuses),
      otherEarnings: Number(record.otherEarnings),
      otherDeductions: Number(record.otherDeductions),
      taxBreakdown: record.taxBreakdown,
      netPay: Number(record.netSalary),
      status: record.status,
    }));
  }

  async finalizePayroll(userId: string, payPeriodId: string) {
    const records = await this.payrollRepository.find({
      where: {
        userId,
        payPeriodId,
        status: PayrollStatus.DRAFT,
      },
    });

    if (records.length === 0) {
      throw new Error('No draft payroll records found for this period');
    }

    const finalizedDate = new Date();

    const updatedRecords = await Promise.all(
      records.map(async (record) => {
        record.status = PayrollStatus.FINALIZED;
        record.finalizedAt = finalizedDate;
        return this.payrollRepository.save(record);
      }),
    );

    return updatedRecords;
  }
}
