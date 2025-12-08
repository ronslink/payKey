import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from '../entities/worker.entity';
import { Termination } from '../entities/termination.entity';
import { PayrollRecord } from '../../payroll/entities/payroll-record.entity';
import { PayPeriod } from '../../payroll/entities/pay-period.entity';
import { TaxesService } from '../../taxes/taxes.service';
import {
  CreateTerminationDto,
  FinalPaymentCalculationDto,
} from '../dto/termination.dto';

@Injectable()
export class TerminationService {
  constructor(
    @InjectRepository(Worker)
    private workerRepository: Repository<Worker>,
    @InjectRepository(Termination)
    private terminationRepository: Repository<Termination>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    private taxesService: TaxesService,
  ) { }

  /**
   * Calculate final payment for a worker
   * Includes prorated salary and unused leave payout
   */
  async calculateFinalPayment(
    workerId: string,
    userId: string,
    terminationDate: Date,
  ): Promise<FinalPaymentCalculationDto> {
    const worker = await this.workerRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (!worker.isActive) {
      throw new BadRequestException('Worker is already terminated');
    }

    const grossSalary = Number(worker.salaryGross);

    // Calculate prorated salary based on days worked in the month
    const termDate = new Date(terminationDate);
    const year = termDate.getFullYear();
    const month = termDate.getMonth();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysWorked = termDate.getDate(); // 1-indexed, so if terminated on 15th, worked 15 days
    const dailyRate = grossSalary / daysInMonth;
    const proratedSalary = dailyRate * daysWorked;

    // Calculate unused leave payout
    const unusedLeaveDays = worker.leaveBalance || 0;
    const leavePayoutRate = dailyRate;
    const unusedLeavePayout = unusedLeaveDays * leavePayoutRate;

    // Severance pay - will be entered manually
    const severancePay = 0;

    // Calculate total gross
    const totalGross = proratedSalary + unusedLeavePayout + severancePay;

    // Calculate tax deductions on final payment
    const taxCalculation = await this.taxesService.calculatePayroll(
      worker.id,
      worker.name,
      totalGross,
    );

    return {
      proratedSalary: Math.round(proratedSalary * 100) / 100,
      unusedLeavePayout: Math.round(unusedLeavePayout * 100) / 100,
      severancePay: Math.round(severancePay * 100) / 100,
      totalGross: Math.round(totalGross * 100) / 100,
      taxDeductions: {
        nssf: taxCalculation.taxBreakdown.nssf,
        nhif: taxCalculation.taxBreakdown.nhif,
        housingLevy: taxCalculation.taxBreakdown.housingLevy,
        paye: taxCalculation.taxBreakdown.paye,
        total: taxCalculation.taxBreakdown.totalDeductions,
      },
      totalNet: taxCalculation.netPay,
      breakdown: {
        daysWorked,
        totalDaysInMonth: daysInMonth,
        dailyRate: Math.round(dailyRate * 100) / 100,
        unusedLeaveDays,
        leavePayoutRate: Math.round(leavePayoutRate * 100) / 100,
      },
    };
  }

  /**
   * Terminate a worker and create termination record
   */
  async terminateWorker(
    workerId: string,
    userId: string,
    dto: CreateTerminationDto,
  ): Promise<Termination> {
    const worker = await this.workerRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (!worker.isActive) {
      throw new BadRequestException('Worker is already terminated');
    }

    // Calculate final payment
    const terminationDate = new Date(dto.terminationDate);
    const finalPayment = await this.calculateFinalPayment(
      workerId,
      userId,
      terminationDate,
    );

    // Use manual severance and outstanding payments if provided
    const severancePay = dto.severancePay ?? 0;
    const outstandingPayments = dto.outstandingPayments ?? 0;
    const totalGross =
      finalPayment.proratedSalary +
      finalPayment.unusedLeavePayout +
      severancePay +
      outstandingPayments;

    // Recalculate taxes on total amount
    const taxCalculation = await this.taxesService.calculatePayroll(
      worker.id,
      worker.name,
      totalGross,
    );

    // Find the Pay Period covering this termination date
    const payPeriod = await this.payPeriodRepository.createQueryBuilder('period')
      .where('period.userId = :userId', { userId })
      .andWhere('period.startDate <= :date', { date: terminationDate })
      .andWhere('period.endDate >= :date', { date: terminationDate })
      .getOne();

    if (payPeriod) {
      // Check if a record already exists
      let payrollRecord = await this.payrollRecordRepository.findOne({
        where: { payPeriodId: payPeriod.id, workerId, userId }
      });

      if (!payrollRecord) {
        payrollRecord = this.payrollRecordRepository.create({
          payPeriodId: payPeriod.id,
          workerId,
          userId,
          periodStart: payPeriod.startDate,
          periodEnd: payPeriod.endDate,
        });
      }

      // Update record with final payment details
      payrollRecord.grossSalary = totalGross;
      payrollRecord.netSalary = taxCalculation.netPay;
      payrollRecord.taxAmount = taxCalculation.taxBreakdown.paye;
      payrollRecord.taxBreakdown = {
        nssf: taxCalculation.taxBreakdown.nssf,
        nhif: taxCalculation.taxBreakdown.nhif,
        housingLevy: taxCalculation.taxBreakdown.housingLevy,
        paye: taxCalculation.taxBreakdown.paye,
        totalDeductions: taxCalculation.taxBreakdown.totalDeductions
      };

      // Mark as finalized termination pay
      payrollRecord.status = 'finalized' as any; // Import Enum if possible, otherwise cast
      payrollRecord.finalizedAt = new Date();
      payrollRecord.otherEarnings = severancePay + outstandingPayments; // Track this separately?
      payrollRecord.deductions = {};

      await this.payrollRecordRepository.save(payrollRecord);

      // Trigger Tax Submission Generation/Update
      try {
        await this.taxesService.generateTaxSubmission(payPeriod.id, userId);
      } catch (e) {
        console.warn('Failed to update tax submission after termination:', e);
      }
    } else {
      console.warn(`No pay period found for termination date ${terminationDate}. Tax liability may not be recorded.`);
    }

    // Create termination record
    const termination = this.terminationRepository.create({
      workerId,
      userId,
      reason: dto.reason,
      terminationDate,
      lastWorkingDate: dto.lastWorkingDate
        ? new Date(dto.lastWorkingDate)
        : terminationDate,
      noticePeriodDays: dto.noticePeriodDays || 0,
      notes: dto.notes,
      proratedSalary: finalPayment.proratedSalary,
      unusedLeavePayout: finalPayment.unusedLeavePayout,
      severancePay,
      totalFinalPayment: taxCalculation.netPay,
      paymentBreakdown: {
        ...finalPayment.breakdown,
        severancePay,
        outstandingPayments,
      },
    });

    const savedTermination = await this.terminationRepository.save(termination);

    // Update worker status (soft delete)
    worker.isActive = false;
    worker.terminatedAt = terminationDate;
    worker.terminationId = savedTermination.id;
    await this.workerRepository.save(worker);

    return savedTermination;
  }

  /**
   * Get termination history for a user
   */
  async getTerminationHistory(userId: string): Promise<Termination[]> {
    return this.terminationRepository.find({
      where: { userId },
      relations: ['worker'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get termination details by ID
   */
  async getTermination(id: string, userId: string): Promise<Termination> {
    const termination = await this.terminationRepository.findOne({
      where: { id, userId },
      relations: ['worker'],
    });

    if (!termination) {
      throw new NotFoundException('Termination record not found');
    }

    return termination;
  }
}
