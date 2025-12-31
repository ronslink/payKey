
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { PayPeriod } from './src/modules/payroll/entities/pay-period.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

const MONTH_NAMES = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
];

async function bootstrap() {
    process.env.DB_HOST = 'localhost';
    const app = await NestFactory.createApplicationContext(AppModule);

    try {
        const repo = app.get<Repository<PayPeriod>>(getRepositoryToken(PayPeriod));

        // Fix specific period from error logs
        const periodId = '2e99a2d5-374b-4035-a0ce-1d98f3d11ad7';
        const period = await repo.findOne({ where: { id: periodId } });

        if (period) {
            console.log('Found period:', period.id, 'name:', period.name, 'userId:', period.userId);
            if (!period.name || period.name.trim() === '') {
                const month = MONTH_NAMES[new Date(period.startDate).getMonth()];
                const year = new Date(period.startDate).getFullYear();
                period.name = `${month} ${year}`;
                await repo.save(period);
                console.log(`FIXED: "${period.name}"`);
            }
        } else {
            console.log('Period not found, checking all periods...');
        }

        // Also fix ANY period with null name
        const allPeriods = await repo.find();
        console.log(`\nChecking all ${allPeriods.length} periods for null names...`);

        let fixed = 0;
        for (const p of allPeriods) {
            if (!p.name || p.name.trim() === '') {
                const month = MONTH_NAMES[new Date(p.startDate).getMonth()];
                const year = new Date(p.startDate).getFullYear();
                p.name = `${month} ${year}`;
                await repo.save(p);
                console.log(`Fixed: ${p.id} -> "${p.name}"`);
                fixed++;
            }
        }

        console.log(`\nTotal fixed: ${fixed}`);

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
