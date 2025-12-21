const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./src/app.module');
const { DataSource } = require('typeorm');
const { Worker, EmploymentType, PaymentFrequency } = require('./src/modules/workers/entities/worker.entity');
const { PayPeriod } = require('./src/modules/payroll/entities/pay-period.entity');
const { PayrollRecord } = require('./src/modules/payroll/entities/payroll-record.entity');
const { Transaction } = require('./src/modules/payments/entities/transaction.entity');

async function seedCompleteDemoData() {
  console.log('🌱 Starting comprehensive demo data seeding...\n');
  
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);
  
  const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
  
  try {
    // 1. Create Pay Periods
    console.log('📅 Creating pay periods...');
    const payPeriodRepository = dataSource.getRepository(PayPeriod);
    
    const payPeriods = [
      {
        userId: demoUserId,
        title: 'January 2025',
        periodStart: new Date('2025-01-01'),
        periodEnd: new Date('2025-01-31'),
        status: 'CLOSED',
        isActive: false,
        processedAt: new Date('2025-02-01')
      },
      {
        userId: demoUserId,
        title: 'February 2025',
        periodStart: new Date('2025-02-01'),
        periodEnd: new Date('2025-02-28'),
        status: 'CLOSED',
        isActive: false,
        processedAt: new Date('2025-03-01')
      },
      {
        userId: demoUserId,
        title: 'March 2025',
        periodStart: new Date('2025-03-01'),
        periodEnd: new Date('2025-03-31'),
        status: 'PROCESSING',
        isActive: true
      }
    ];
    
    for (const period of payPeriods) {
      const existingPeriod = await payPeriodRepository.findOne({
        where: { title: period.title, userId: demoUserId }
      });
      
      if (!existingPeriod) {
        await payPeriodRepository.save(period);
        console.log(`✅ Created pay period: ${period.title}`);
      } else {
        console.log(`📋 Pay period already exists: ${period.title}`);
      }
    }
    
    // 2. Create Payroll Records
    console.log('\n💰 Creating payroll records...');
    const workerRepository = dataSource.getRepository(Worker);
    const payrollRecordRepository = dataSource.getRepository(PayrollRecord);
    
    const workers = await workerRepository.find({
      where: { userId: demoUserId }
    });
    
    const payrollPeriods = await payPeriodRepository.find({
      where: { userId: demoUserId, status: 'CLOSED' }
    });
    
    for (const period of payrollPeriods) {
      for (const worker of workers) {
        // Calculate payroll amounts
        const grossSalary = parseFloat(worker.salaryGross);
        const housingAllowance = parseFloat(worker.housingAllowance || 0);
        const transportAllowance = parseFloat(worker.transportAllowance || 0);
        const totalGross = grossSalary + housingAllowance + transportAllowance;
        
        // Simple tax calculation (20% of gross)
        const taxAmount = totalGross * 0.20;
        const netSalary = totalGross - taxAmount;
        
        const payrollData = {
          userId: demoUserId,
          workerId: worker.id,
          periodStart: period.periodStart,
          periodEnd: period.periodEnd,
          grossSalary: totalGross,
          bonuses: 0,
          otherEarnings: 0,
          otherDeductions: 0,
          netSalary: netSalary,
          taxAmount: taxAmount,
          status: 'PAID',
          paymentStatus: 'PAID',
          paymentMethod: worker.paymentMethod,
          paymentDate: period.processedAt,
          finalizedAt: period.processedAt
        };
        
        const existingPayroll = await payrollRecordRepository.findOne({
          where: {
            workerId: worker.id,
            periodStart: period.periodStart,
            periodEnd: period.periodEnd
          }
        });
        
        if (!existingPayroll) {
          await payrollRecordRepository.save(payrollData);
          console.log(`✅ Payroll created for ${worker.name} - ${period.title}`);
        }
      }
    }
    
    // 3. Create Transactions
    console.log('\n💳 Creating payment transactions...');
    const transactionRepository = dataSource.getRepository(Transaction);
    
    const payrollRecords = await payrollRecordRepository.find({
      where: { userId: demoUserId },
      relations: ['worker']
    });
    
    for (const record of payrollRecords) {
      const transactionData = {
        userId: demoUserId,
        workerId: record.workerId,
        amount: record.netSalary,
        currency: 'KES',
        type: 'PAYROLL',
        status: 'COMPLETED',
        providerRef: `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        metadata: {
          payPeriod: `${record.periodStart.toISOString().split('T')[0]} to ${record.periodEnd.toISOString().split('T')[0]}`,
          grossSalary: record.grossSalary,
          taxAmount: record.taxAmount,
          netSalary: record.netSalary
        }
      };
      
      const existingTransaction = await transactionRepository.findOne({
        where: {
          workerId: record.workerId,
          amount: record.netSalary,
          type: 'PAYROLL'
        }
      });
      
      if (!existingTransaction) {
        await transactionRepository.save(transactionData);
        console.log(`✅ Transaction created for ${record.worker.name} - KES ${record.netSalary}`);
      }
    }
    
    console.log('\n🎉 Demo data seeding completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   • Pay Periods: ${payrollPeriods.length}`);
    console.log(`   • Workers: ${workers.length}`);
    console.log(`   • Payroll Records: ${payrollRecords.length}`);
    console.log(`   • Transactions: ${payrollRecords.length}`);
    
  } catch (error) {
    console.error('❌ Error seeding demo data:', error);
  } finally {
    await app.close();
  }
}

// Run the seeding
seedCompleteDemoData();
