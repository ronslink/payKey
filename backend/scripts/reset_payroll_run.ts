
import { DataSource } from 'typeorm';
import { PayPeriod } from '../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../src/modules/payroll/entities/payroll-record.entity';
import { User } from '../src/modules/users/entities/user.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { Property } from '../src/modules/properties/entities/property.entity';
// import dataSource from '../../ormconfig'; // We will create local one

async function resetPayroll() {
    const email = process.argv[2];
    const dateStr = process.argv[3] || '2025-12';

    if (!email) {
        console.error('Please provide email as first argument');
        process.exit(1);
    }


    console.log(`Connecting to database...`);
    // Create ad-hoc connection with explicit entities
    const appDataSource = new DataSource({
        type: 'postgres',
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432'),
        username: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'admin',
        database: process.env.DB_NAME || 'paykey',
        entities: [User, PayPeriod, PayrollRecord, Worker, Property], // Added Worker just in case
        synchronize: false,
        logging: false,
    });

    await appDataSource.initialize();
    const dataSource = appDataSource;

    try {
        console.log(`Finding user ${email}...`);
        const user = await dataSource.getRepository(User).findOne({ where: { email } });
        if (!user) {
            console.error('User not found');
            process.exit(1);
        }

        console.log(`Finding pay period for ${dateStr}...`);
        const payPeriodRepo = dataSource.getRepository(PayPeriod);
        const payPeriod = await payPeriodRepo.createQueryBuilder('pp')
            .where('pp.userId = :userId', { userId: user.id })
            .andWhere('pp.startDate::text LIKE :date', { date: `${dateStr}%` })
            .getOne();

        if (!payPeriod) {
            console.error('Pay period not found');
            process.exit(1);
        }

        console.log(`Found PayPeriod: ${payPeriod.id} (${payPeriod.status})`);

        console.log('Resetting Payroll Records...');
        const recordRepo = dataSource.getRepository(PayrollRecord);
        const updateResult = await recordRepo.update(
            { payPeriodId: payPeriod.id },
            {
                status: 'draft' as any,
                finalizedAt: null as any,
                paymentStatus: 'pending' as any
            }
        );
        console.log(`Updated ${updateResult.affected} records.`);

        console.log('Resetting Pay Period status...');
        await payPeriodRepo.update(
            { id: payPeriod.id },
            { status: 'DRAFT' as any }
        );
        console.log('Pay Period reset to DRAFT.');

        console.log('Done.');

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await dataSource.destroy();
    }
}

resetPayroll();
