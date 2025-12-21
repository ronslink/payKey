import * as dotenv from 'dotenv';
dotenv.config();
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { TaxesService } from '../src/modules/taxes/taxes.service';
import { UsersService } from '../src/modules/users/users.service';
import { UserRole } from '../src/modules/users/entities/user.entity';
import { TaxTable } from '../src/modules/taxes/entities/tax-table.entity';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const taxesService = app.get(TaxesService);
  const usersService = app.get(UsersService);

  console.log('Seeding tax tables...');

  // Check if any tax table exists
  const existingTables = await taxesService.getTaxTables();
  if (existingTables.length === 0) {
    console.log('No tax tables found. Creating default 2024/2025 table...');
    await taxesService.createTaxTable({
      year: 2024,
      effectiveDate: new Date('2024-01-01'),
      nssfConfig: {
        tierILimit: 7000,
        tierIILimit: 36000,
        rate: 0.06,
      },
      nhifConfig: {
        rate: 0.0275, // SHIF rate
      },
      housingLevyRate: 0.015,
      payeBands: [
        { limit: 24000, rate: 0.1 },
        { limit: 32333, rate: 0.25 },
        { limit: Infinity, rate: 0.3 },
      ],
      personalRelief: 2400,
      isActive: true,
    });
    console.log('Default tax table created.');
  } else {
    console.log('Tax tables already exist.');
  }

  // Optional: Promote a user to ADMIN for testing
  // const adminEmail = 'admin@paykey.com';
  // const user = await usersService.findOneByEmail(adminEmail);
  // if (user) {
  //     user.role = UserRole.ADMIN;
  //     await usersService.update(user.id, user); // Assuming update method exists
  //     console.log(`User ${adminEmail} promoted to ADMIN.`);
  // }

  await app.close();
}

bootstrap();
