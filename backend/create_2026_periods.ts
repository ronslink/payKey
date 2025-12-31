
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { UsersService } from './src/modules/users/users.service';
import { PayPeriod, PayPeriodStatus, PayPeriodFrequency } from './src/modules/payroll/entities/pay-period.entity';
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
        const usersService = app.get(UsersService);
        const repo = app.get<Repository<PayPeriod>>(getRepositoryToken(PayPeriod));

        const email = 'testuser@paykey.com';
        const user = await usersService.findOneByEmail(email);

        if (!user) {
            console.log(`User ${email} not found`);
            return;
        }

        console.log(`User found: ${user.id}`);

        // Check for existing 2026 periods
        const existing2026 = await repo.find({
            where: { userId: user.id },
        });
        const existing2026Periods = existing2026.filter(p => new Date(p.startDate).getFullYear() === 2026);

        if (existing2026Periods.length > 0) {
            console.log(`User already has ${existing2026Periods.length} periods in 2026:`);
            existing2026Periods.forEach(p => console.log(`  - ${p.name} (${p.status})`));
            console.log('\nSkipping creation to avoid duplicates.');
            return;
        }

        // Create 12 monthly periods for 2026
        console.log('\nCreating 2026 pay periods...\n');

        for (let month = 0; month < 12; month++) {
            const startDate = new Date(2026, month, 1);
            const endDate = new Date(2026, month + 1, 0); // Last day of month

            const period = repo.create({
                name: `${MONTH_NAMES[month]} 2026`,
                startDate: startDate.toISOString().split('T')[0],
                endDate: endDate.toISOString().split('T')[0],
                payDate: endDate.toISOString().split('T')[0],
                frequency: PayPeriodFrequency.MONTHLY,
                status: PayPeriodStatus.DRAFT,
                userId: user.id,
                isOffCycle: false,
            });

            await repo.save(period);
            console.log(`Created: ${period.name} (${startDate.toISOString().split('T')[0]} to ${endDate.toISOString().split('T')[0]})`);
        }

        console.log('\nDone! Created 12 monthly periods for 2026.');

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
