import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DataSource } from 'typeorm';
import {
  Worker,
} from './modules/workers/entities/worker.entity';
import {
  PayPeriod,
  PayPeriodStatus,
  PayPeriodFrequency,
} from './modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from './modules/payroll/entities/payroll-record.entity';
import { User } from './modules/users/entities/user.entity';
import * as bcrypt from 'bcrypt';
import {
  PaymentFrequency,
  EmploymentType,
} from './modules/workers/entities/worker.entity';

async function seedDemoData() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  try {
    // First, clean existing data
    console.log('Cleaning existing demo data...');
    await dataSource.getRepository(PayrollRecord).delete({});
    await dataSource.getRepository(PayPeriod).delete({});
    await dataSource.getRepository(Worker).delete({});
    await dataSource.getRepository(User).delete({ email: 'testuser@paykey.com' });

    console.log('Creating demo user...');
    const userRepository = dataSource.getRepository(User);
    const workerRepository = dataSource.getRepository(Worker);
    const payPeriodRepository = dataSource.getRepository(PayPeriod);
    const payrollRecordRepository = dataSource.getRepository(PayrollRecord);

    // Create demo user
    const demoUser = userRepository.create({
      email: 'testuser@paykey.com',
      firstName: 'Test',
      lastName: 'User',
      passwordHash: await bcrypt.hash('password123', 10),
    });
    await userRepository.save(demoUser);

    // Create 5 demo workers with realistic details
    console.log('Creating demo workers...');
    const demoWorkers: Partial<Worker>[] = [
      {
        name: 'John Kamau Mwangi',
        email: 'john.kamau@company.com',
        phoneNumber: '+254701234567',
        idNumber: '12345678',
        kraPin: 'A123456789B',
        nssfNumber: 'NSSF123456',
        nhifNumber: 'NHIF789012',
        jobTitle: 'Software Developer',
        salaryGross: 120000, // 120K per month
        hourlyRate: 692.31, // Based on monthly salary
        employmentType: EmploymentType.FIXED,
        paymentFrequency: PaymentFrequency.MONTHLY,
        startDate: new Date('2023-01-15'),
        isActive: true,
        housingAllowance: 25000,
        transportAllowance: 15000,
        mpesaNumber: '+254701234567',
        user: demoUser,
        userId: demoUser.id,
      },
      {
        name: 'Sarah Wanjiku Njeri',
        email: 'sarah.wanjiku@company.com',
        phoneNumber: '+254702345678',
        idNumber: '23456789',
        kraPin: 'B987654321C',
        nssfNumber: 'NSSF234567',
        nhifNumber: 'NHIF890123',
        jobTitle: 'Marketing Manager',
        salaryGross: 85000,
        hourlyRate: 489.66,
        employmentType: EmploymentType.FIXED,
        paymentFrequency: PaymentFrequency.MONTHLY,
        startDate: new Date('2022-08-01'),
        isActive: true,
        housingAllowance: 18000,
        transportAllowance: 12000,
        mpesaNumber: '+254702345678',
        user: demoUser,
        userId: demoUser.id,
      },
      {
        name: 'Michael Ochieng Otieno',
        email: 'michael.ochieng@company.com',
        phoneNumber: '+254703456789',
        idNumber: '34567890',
        kraPin: 'C876543210D',
        nssfNumber: 'NSSF345678',
        nhifNumber: 'NHIF901234',
        jobTitle: 'Construction Worker',
        salaryGross: 0,
        hourlyRate: 500,
        employmentType: EmploymentType.HOURLY,
        paymentFrequency: PaymentFrequency.WEEKLY,
        startDate: new Date('2023-06-01'),
        isActive: true,
        mpesaNumber: '+254703456789',
        user: demoUser,
        userId: demoUser.id,
      },
      {
        name: 'Grace Achieng Adhiambo',
        email: 'grace.achieng@company.com',
        phoneNumber: '+254704567890',
        idNumber: '45678901',
        kraPin: 'D765432109E',
        nssfNumber: 'NSSF456789',
        nhifNumber: 'NHIF012345',
        jobTitle: 'HR Specialist',
        salaryGross: 65000,
        hourlyRate: 374.14,
        employmentType: EmploymentType.FIXED,
        paymentFrequency: PaymentFrequency.MONTHLY,
        startDate: new Date('2023-03-01'),
        isActive: true,
        housingAllowance: 15000,
        transportAllowance: 10000,
        mpesaNumber: '+254704567890',
        user: demoUser,
        userId: demoUser.id,
      },
      {
        name: 'David Kiprotich Chepkemoi',
        email: 'david.kiprotich@company.com',
        phoneNumber: '+254705678901',
        idNumber: '56789012',
        kraPin: 'E654321098F',
        nssfNumber: 'NSSF567890',
        nhifNumber: 'NHIF123456',
        jobTitle: 'Accountant',
        salaryGross: 95000,
        hourlyRate: 546.51,
        employmentType: EmploymentType.FIXED,
        paymentFrequency: PaymentFrequency.MONTHLY,
        startDate: new Date('2022-11-01'),
        isActive: true,
        housingAllowance: 20000,
        transportAllowance: 14000,
        mpesaNumber: '+254705678901',
        user: demoUser,
        userId: demoUser.id,
      },
    ];

    const savedWorkers = await workerRepository.save(demoWorkers);
    console.log(`Created ${savedWorkers.length} demo workers`);

    // Create pay periods for the last 3 months (bi-weekly)
    console.log('Creating pay periods for the last 3 months...');
    const currentDate = new Date();
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(currentDate.getMonth() - 3);

    const payPeriods: Partial<PayPeriod>[] = [];
    const periodStart = new Date(threeMonthsAgo);

    // Generate bi-weekly periods for 3 months
    let currentPeriodStart = new Date(periodStart);
    while (currentPeriodStart <= currentDate) {
      const periodEnd = new Date(currentPeriodStart);
      periodEnd.setDate(periodEnd.getDate() + 13); // 2 weeks = 14 days, but end date is inclusive

      if (periodEnd > currentDate) break;

      const payDate = new Date(periodEnd);
      payDate.setDate(payDate.getDate() + 3); // Pay 3 days after period end

      const periodName = `${currentPeriodStart.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })} - Week ${Math.ceil(currentPeriodStart.getDate() / 14)}`;

      payPeriods.push({
        name: periodName,
        startDate: currentPeriodStart,
        endDate: periodEnd,
        payDate: payDate.toISOString().split('T')[0],
        frequency: PayPeriodFrequency.BIWEEKLY,
        status: PayPeriodStatus.COMPLETED, // Most periods will be completed
        createdBy: demoUser.id,
        processedAt: new Date(periodEnd.getTime() + 24 * 60 * 60 * 1000), // Next day
      });

      // Move to next period (14 days)
      currentPeriodStart.setDate(currentPeriodStart.getDate() + 14);
    }

    const savedPayPeriods = await payPeriodRepository.save(payPeriods);
    console.log(`Created ${savedPayPeriods.length} pay periods`);

    // Create payroll records with varied scenarios
    console.log('Creating payroll records with varied scenarios...');
    const payrollRecords: Partial<PayrollRecord>[] = [];

    for (const payPeriod of savedPayPeriods) {
      for (const worker of savedWorkers) {
        // Calculate gross salary based on employment type
        let grossSalary = 0;

        if (worker.employmentType === EmploymentType.FIXED) {
          // For monthly salaried workers, calculate based on pay period frequency
          const monthlySalary = worker.salaryGross;
          switch (payPeriod.frequency) {
            case PayPeriodFrequency.BIWEEKLY:
              grossSalary = monthlySalary / 2;
              break;
            case PayPeriodFrequency.MONTHLY:
              grossSalary = monthlySalary;
              break;
            case PayPeriodFrequency.WEEKLY:
              grossSalary = monthlySalary / 4;
              break;
          }

          // Add allowances
          const housingAllowance = Number(worker.housingAllowance) || 0;
          const transportAllowance = Number(worker.transportAllowance) || 0;
          grossSalary += housingAllowance + transportAllowance;

          // Add overtime for some workers (20% chance)
          if (Math.random() < 0.2) {
            grossSalary *= 1.2; // 20% overtime
          }
        } else {
          // For hourly workers, calculate hours worked
          const hoursWorked = 80 + Math.floor(Math.random() * 40); // 80-120 hours per bi-weekly period
          grossSalary = Number(worker.hourlyRate) * hoursWorked;

          // Add overtime (hours over 80)
          const overtimeHours = Math.max(0, hoursWorked - 80);
          if (overtimeHours > 0) {
            grossSalary += overtimeHours * Number(worker.hourlyRate) * 1.5; // 1.5x overtime rate
          }
        }

        // Calculate tax (simplified progressive tax)
        const taxAmount = calculateTax(grossSalary);
        const netSalary = grossSalary - taxAmount;

        // Vary payment status
        let paymentStatus = 'paid';
        const random = Math.random();
        if (random < 0.1) paymentStatus = 'pending';
        else if (random < 0.05) paymentStatus = 'processing';

        payrollRecords.push({
          userId: demoUser.id,
          workerId: worker.id,
          periodStart: payPeriod.startDate,
          periodEnd: payPeriod.endDate,
          grossSalary: Math.round(grossSalary * 100) / 100,
          netSalary: Math.round(netSalary * 100) / 100,
          taxAmount: Math.round(taxAmount * 100) / 100,
          paymentStatus,
          paymentMethod: 'mpesa',
          paymentDate: paymentStatus === 'paid' ? new Date(payPeriod.payDate) : undefined,
          taxBreakdown: {
            incomeTax: taxAmount,
            nhif: Math.min(grossSalary * 0.015, 300), // 1.5% up to 300
            nssf: Math.min(grossSalary * 0.06, 200), // 6% up to 200
            grossSalary,
            netSalary,
          },
          deductions: {
            loanDeduction: Math.random() < 0.1 ? Math.round(grossSalary * 0.1 * 100) / 100 : 0,
            insurance: Math.round(grossSalary * 0.02 * 100) / 100,
          },
        });
      }
    }

    const savedPayrollRecords = await payrollRecordRepository.save(payrollRecords);
    console.log(`Created ${savedPayrollRecords.length} payroll records`);

    // Update pay period totals
    console.log('Updating pay period totals...');
    for (const payPeriod of savedPayPeriods) {
      const periodRecords = savedPayrollRecords.filter(
        (r) => r.periodStart.getTime() === payPeriod.startDate.getTime() && r.periodEnd.getTime() === payPeriod.endDate.getTime(),
      );

      const totals = periodRecords.reduce(
        (acc, record) => ({
          grossAmount: acc.grossAmount + Number(record.grossSalary),
          netAmount: acc.netAmount + Number(record.netSalary),
          taxAmount: acc.taxAmount + Number(record.taxAmount),
          processedWorkers: acc.processedWorkers + 1,
        }),
        { grossAmount: 0, netAmount: 0, taxAmount: 0, processedWorkers: 0 },
      );

      await payPeriodRepository.update(payPeriod.id, {
        totalGrossAmount: totals.grossAmount,
        totalNetAmount: totals.netAmount,
        totalTaxAmount: totals.taxAmount,
        totalWorkers: periodRecords.length,
        processedWorkers: totals.processedWorkers,
      });
    }

    console.log('\n=== Demo Data Summary ===');
    console.log(`✅ Demo User: ${demoUser.email}`);
    console.log(`✅ Created ${savedWorkers.length} workers`);
    console.log(`✅ Created ${savedPayPeriods.length} pay periods`);
    console.log(`✅ Created ${savedPayrollRecords.length} payroll records`);
    console.log('\nLogin with: testuser@paykey.com / password123');

  } catch (error) {
    console.error('Error seeding demo data:', error);
  } finally {
    await app.close();
  }
}

// Simplified progressive tax calculation for Kenya
function calculateTax(grossSalary: number): number {
  let tax = 0;

  // P.A.Y.E Tax brackets (simplified)
  if (grossSalary > 1000000 / 12) {
    // Over 83,333/month
    tax += (grossSalary - 83333) * 0.25;
    grossSalary = 83333;
  }
  if (grossSalary > 500000 / 12) {
    // Over 41,667/month
    tax += (grossSalary - 41667) * 0.20;
    grossSalary = 41667;
  }
  if (grossSalary > 240000 / 12) {
    // Over 20,000/month
    tax += (grossSalary - 20000) * 0.15;
    grossSalary = 20000;
  }
  if (grossSalary > 120000 / 12) {
    // Over 10,000/month
    tax += (grossSalary - 10000) * 0.10;
  }

  // Personal relief
  tax = Math.max(0, tax - 2400 / 12); // 2,400 per year personal relief

  return Math.round(tax * 100) / 100;
}

// Run the seed
seedDemoData().catch(console.error);
