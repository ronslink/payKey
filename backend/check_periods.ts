
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { UsersService } from './src/modules/users/users.service';
import { PayPeriod } from './src/modules/payroll/entities/pay-period.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

async function bootstrap() {
    process.env.DB_HOST = 'localhost';

    const app = await NestFactory.createApplicationContext(AppModule);

    try {
        const usersService = app.get(UsersService);
        const payPeriodsRepository = app.get<Repository<PayPeriod>>(getRepositoryToken(PayPeriod));

        const email = 'testuser@paykey.com';
        const user = await usersService.findOneByEmail(email);

        if (!user) {
            console.log(`User ${email} not found`);
            return;
        }

        console.log(`User found: ${user.id}`);

        // Fetch via repo (read only)
        const periods = await payPeriodsRepository.find({
            where: { userId: user.id },
            order: { startDate: 'ASC' }
        });

        console.log(`\nTotal periods: ${periods.length}`);
        console.log('----------------------------------------');

        // Group by year
        const byYear = new Map<number, PayPeriod[]>();
        for (const p of periods) {
            const year = new Date(p.startDate).getFullYear();
            if (!byYear.has(year)) byYear.set(year, []);
            byYear.get(year)!.push(p);
        }

        for (const [year, yearPeriods] of byYear) {
            console.log(`\n=== ${year} (${yearPeriods.length} periods) ===`);
            for (const p of yearPeriods) {
                console.log(`  ${p.name || 'Unnamed'} | Status: ${p.status} | ${p.startDate} to ${p.endDate}`);
            }
        }

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
