
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { UsersService } from './src/modules/users/users.service';
import { PayPeriodsService } from './src/modules/payroll/pay-periods.service';
import { PayPeriod } from './src/modules/payroll/entities/pay-period.entity';
import { PayPeriodStatus } from './src/modules/payroll/entities/pay-period.entity';
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

        // Fetch via repo
        const periods = await payPeriodsRepository.find({ where: { userId: user.id } });

        // Filter 2025
        const periods2025 = periods.filter(p => new Date(p.startDate).getFullYear() === 2025);

        if (periods2025.length > 0) {
            console.log('Force Closing 2025 periods via Repository...');
            for (const p of periods2025) {
                p.status = PayPeriodStatus.COMPLETED; // Force to COMPLETED
                await payPeriodsRepository.save(p);
                process.stdout.write('.');
            }
            console.log('\n2025 periods force closed.');
        } else {
            console.log('No 2025 periods to close.');
        }

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
