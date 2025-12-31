
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

        // Get ALL periods for user 9a25fc39...
        const userId = '9a25fc39-c191-4927-af06-963ff779e64e';
        const periods = await repo.find({
            where: { userId },
            order: { startDate: 'ASC' }
        });

        console.log(`\n=== User ${userId} has ${periods.length} periods ===\n`);

        for (const p of periods) {
            const year = new Date(p.startDate).getFullYear();
            const needsFix = !p.name || p.name.trim() === '';

            if (needsFix) {
                const month = MONTH_NAMES[new Date(p.startDate).getMonth()];
                p.name = `${month} ${year}`;
                await repo.save(p);
                console.log(`FIXED: ${p.id} -> "${p.name}" (${p.status})`);
            } else {
                console.log(`OK: ${p.name} (${p.status}) - ${year}`);
            }
        }

        console.log('\nDone.');

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
