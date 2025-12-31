
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { UsersService } from './src/modules/users/users.service';
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
        const usersService = app.get(UsersService);
        const payPeriodsRepository = app.get<Repository<PayPeriod>>(getRepositoryToken(PayPeriod));

        const email = 'testuser@paykey.com';
        const user = await usersService.findOneByEmail(email);

        if (!user) {
            console.log(`User ${email} not found`);
            return;
        }

        console.log(`User found: ${user.id}`);

        // Fetch all periods with null names
        const periods = await payPeriodsRepository.find({
            where: { userId: user.id },
            order: { startDate: 'ASC' }
        });

        console.log(`Found ${periods.length} periods`);

        for (const p of periods) {
            if (!p.name || p.name.trim() === '') {
                const startDate = new Date(p.startDate);
                const month = MONTH_NAMES[startDate.getMonth()];
                const year = startDate.getFullYear();
                const newName = `${month} ${year}`;

                p.name = newName;
                await payPeriodsRepository.save(p);
                console.log(`Updated period ${p.id}: "${newName}"`);
            }
        }

        console.log('\nDone fixing names.');

    } catch (e) {
        console.error(e);
    } finally {
        await app.close();
    }
}

bootstrap();
