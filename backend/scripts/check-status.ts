import { DataSource } from 'typeorm';
import { PayPeriod } from '../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../src/modules/payroll/entities/payroll-record.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { TaxSubmission } from '../src/modules/taxes/entities/tax-submission.entity';
import { Transaction } from '../src/modules/payments/entities/transaction.entity';
import { User } from '../src/modules/users/entities/user.entity';

const dataSource = new DataSource({
    type: 'postgres',
    host: 'localhost',
    port: 5435,
    username: 'postgres',
    password: 'admin',
    database: 'paykey',
    entities: [__dirname + '/../modules/**/*.entity.ts'],
    synchronize: false,
});

async function check() {
    try {
        await dataSource.initialize();
        console.log('Connected to DB');

        const periods = await dataSource.getRepository(PayPeriod).find({
            order: { startDate: 'DESC' }
        });
        console.log(`Found ${periods.length} Pay Periods`);

        for (const p of periods) {
            console.log('\n------------------------------------------------');
            console.log(`Period: "${p.name}"`);
            console.log(`ID: ${p.id}`);
            console.log(`Status: ${p.status}`);
            console.log(`Dates: ${p.startDate} - ${p.endDate}`);

            const recordRepo = dataSource.getRepository(PayrollRecord);
            const records = await recordRepo.find({ where: { payPeriodId: p.id } });

            console.log(`Total Payroll Records: ${records.length}`);

            const breakdown = records.reduce((acc, r) => {
                acc[r.status] = (acc[r.status] || 0) + 1;
                return acc;
            }, {} as Record<string, number>);

            console.log('Record Statuses:', JSON.stringify(breakdown));

            // Check sample record
            if (records.length > 0) {
                const sample = records[0];
                console.log('Sample Record taxBreakdown:', JSON.stringify(sample.taxBreakdown));
            }

            const subRepo = dataSource.getRepository(TaxSubmission);
            const subs = await subRepo.find({ where: { payPeriodId: p.id } });
            console.log(`Tax Submissions: ${subs.length}`);
            if (subs.length > 0) {
                console.log('Submission Status:', subs[0].status);
                console.log('Submission Totals:', {
                    paye: subs[0].totalPaye,
                    nssf: subs[0].totalNssf,
                    nhif: subs[0].totalNhif,
                    housing: subs[0].totalHousingLevy // Check if this exists
                });
            }
        }

    } catch (e) {
        console.error('Error:', e);
    } finally {
        if (dataSource.isInitialized) {
            await dataSource.destroy();
        }
    }
}

check();
