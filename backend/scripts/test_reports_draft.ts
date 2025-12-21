
import { DataSource } from 'typeorm';
import { PayPeriod } from '../../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../../src/modules/payroll/entities/payroll-record.entity';
import { User } from '../../src/modules/users/entities/user.entity';
import { Worker } from '../../src/modules/workers/entities/worker.entity';
import { Property } from '../../src/modules/properties/entities/property.entity';
import { TaxSubmission } from '../../src/modules/taxes/entities/tax-submission.entity';
import { Transaction } from '../../src/modules/payments/entities/transaction.entity';

async function testReports() {
    const email = 'lex12@yahoo.com';
    const dateStr = '2025-12';

    console.log(`Connecting to database...`);
    const appDataSource = new DataSource({
        type: 'postgres',
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432'),
        username: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'admin',
        database: process.env.DB_NAME || 'paykey',
        entities: [User, PayPeriod, PayrollRecord, Worker, Property, TaxSubmission, Transaction],
        synchronize: false,
        logging: false,
    });

    await appDataSource.initialize();

    try {
        console.log(`Finding user ${email}...`);
        const user = await appDataSource.getRepository(User).findOne({ where: { email } });
        if (!user) throw new Error('User not found');

        console.log(`Finding pay period for ${dateStr}...`);
        const payPeriod = await appDataSource.getRepository(PayPeriod).findOne({
            where: {
                userId: user.id,
                // Using Like on string date is tricky in findOne key value, but we can verify later
                // or just getAll for user and filter in memory since it's a test script
            }
        });
        // Actually, findOne needs exact match or advanced operator. 
        // Let's iterate or assume the ID if we can.
        // Better: use find and filter.
        const allPayPeriods = await appDataSource.getRepository(PayPeriod).find({
            where: { userId: user.id }
        });
        const foundPeriod = allPayPeriods.find(p => p.startDate && p.startDate.toString().startsWith('2025-12'));

        if (!foundPeriod) throw new Error('Pay period not found via list filter');
        const targetPayPeriod = foundPeriod;
        console.log(`Found PayPeriod: ${targetPayPeriod.id} (${targetPayPeriod.status})`);

        // Simulate getPayrollSummaryByPeriod
        console.log('Fetching Payroll Summary...');
        const records = await appDataSource.getRepository(PayrollRecord).find({
            where: {
                payPeriodId: targetPayPeriod.id,
                userId: user.id,
                status: 'finalized' as any
            },
            relations: ['worker'],
        });

        console.log(`Found ${records.length} FINALIZED records.`);

        if (records.length === 0) {
            console.log('No finalized records found. Returning empty summary.');
        }

        const summary = {
            payPeriod: {
                id: targetPayPeriod.id,
                startDate: targetPayPeriod.startDate,
                endDate: targetPayPeriod.endDate,
            },
            totals: {
                grossPay: 0,
                netPay: 0,
                paye: 0,
                nssf: 0,
                nhif: 0,
                housingLevy: 0,
                totalDeductions: 0,
                workerCount: records.length,
            }
        };

        console.log('Result:', JSON.stringify(summary, null, 2));

        // Test P9 Report Logic
        console.log('\nTesting P9 Report Logic...');
        const year = 2025;
        const startDate = new Date(year, 0, 1);
        const endDate = new Date(year, 11, 31, 23, 59, 59);

        const p9Records = await appDataSource.getRepository(PayrollRecord).find({
            where: {
                userId: user.id,
                // periodStart: Between(startDate, endDate), // Need to import Between or use raw
                // Let's just find and filter for simplicity in script
            },
            relations: ['worker'],
        });

        // Filter manually to match logic
        const filteredP9 = p9Records.filter(r => {
            const d = new Date(r.periodStart);
            return d >= startDate && d <= endDate && r.status === 'finalized';
        });

        console.log(`Found ${filteredP9.length} P9 records for ${year}`);
        if (filteredP9.length > 0) {
            console.log('Sample P9 Record Worker:', filteredP9[0].worker?.name);
        } else {
            console.log('No finalized P9 records found (Expected for draft reset).');
        }

        // Test Muster Roll Logic
        console.log('\nTesting Muster Roll Logic...');
        // Since getMusterRoll aliases getPayrollSummaryByPeriod, we just verify it exists and behaves same
        // Mocking the service call or just re-running summary logic
        console.log('Muster Roll uses getPayrollSummaryByPeriod. Verifying data again...');
        const musterRoll = summary; // Effectively the same in current impl
        console.log(`Muster Roll Workers: ${musterRoll.totals.workerCount}`); // Corrected to use totals.workerCount

        if (musterRoll.totals.workerCount === 0) { // Corrected to use totals.workerCount
            console.log('Muster Roll empty (Expected for draft).');
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await appDataSource.destroy();
    }
}

testReports();
```
