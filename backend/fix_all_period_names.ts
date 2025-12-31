
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { PayPeriod } from './src/modules/payroll/entities/pay-period.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';

const MONTH_NAMES = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
];

async function bootstrap() {
    process.env.DB_HOST = 'localhost';

    const app = await NestFactory.createApplicationContext(AppModule);

    try {
        const payPeriodsRepository = app.get<Repository<PayPeriod>>(getRepositoryToken(PayPeriod));

        // Fetch ALL periods with null or empty names across ALL users
        const periods = await payPeriodsRepository.find({
            order: { startDate: 'ASC' }
        });

        console.log(`Found ${periods.length} total periods`);

        let fixed = 0;
        for (const p of periods) {
            if (!p.name || p.name.trim() === '') {
                const startDate = new Date(p.startDate);
                const month = MONTH_NAMES[startDate.getMonth()];
                const year = startDate.getFullYear();
                const newName = `${month} ${year}`;

                p.name = newName;
                await payPeriodsRepository.save(p);
                console.log(`Fixed: ${p.id} -> "${newName}" (user: ${p.userId})`);
                fixed++;
            }
        }

        console.log(`\nDone. Fixed ${fixed} periods.`);

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
