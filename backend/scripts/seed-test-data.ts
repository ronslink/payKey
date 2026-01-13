// src/seed-test-data.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';
import { WorkersService } from '../src/modules/workers/workers.service';
import { Repository } from 'typeorm';
import { User, UserTier } from '../src/modules/users/entities/user.entity';
import {
  Worker,
  EmploymentType,
  PaymentFrequency,
  PaymentMethod,
} from '../src/modules/workers/entities/worker.entity';
import { Activity } from '../src/modules/activities/entities/activity.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';

async function seedTestData() {
  const app = await NestFactory.createApplicationContext(AppModule);

  try {
    const usersService = app.get(UsersService);
    const workersService = app.get(WorkersService);
    const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
    const workerRepo = app.get<Repository<Worker>>(getRepositoryToken(Worker));
    const activityRepo = app.get<Repository<Activity>>(getRepositoryToken(Activity));

    console.log('🌱 Seeding test data...');

    // Clean up existing test data properly
    const emailsToDelete = [
      'test@paykey.com',
      'loadtest@paykey.com',
      'performance-test@paykey.com',
      'testuser@paykey.com',
      'compliance-test@paykey.com'
    ];

    for (const email of emailsToDelete) {
      const user = await userRepo.findOne({ where: { email } });
      if (user) {
        // Delete related activities first
        await activityRepo.delete({ userId: user.id });
        // Delete related workers
        await workerRepo.delete({ userId: user.id });
        // Delete the user
        await userRepo.delete({ id: user.id });
        console.log(`🗑️ Cleaned up data for ${email}`);
      }
    }

    // Create test users
    const testUsers = [
      {
        email: 'test@paykey.com',
        password: 'test-password',
        firstName: 'Test',
        lastName: 'User',
        countryCode: 'KE',
        isOnboardingCompleted: true,
      },
      {
        email: 'loadtest@paykey.com',
        password: 'password123',
        firstName: 'Load',
        lastName: 'Test',
        countryCode: 'KE',
        isOnboardingCompleted: true,
      },
      {
        email: 'performance-test@paykey.com',
        password: 'test-password',
        firstName: 'Performance',
        lastName: 'Test',
        countryCode: 'KE',
        isOnboardingCompleted: true,
      },
      {
        email: 'testuser@paykey.com',
        password: 'testuser123',
        firstName: 'Test',
        lastName: 'User',
        countryCode: 'KE',
        isOnboardingCompleted: true,
        tier: UserTier.PLATINUM,
      },
    ];

    for (const userData of testUsers) {
      const hashedPassword = await bcrypt.hash(userData.password, 10);
      const user = await userRepo.save({
        email: userData.email,
        passwordHash: hashedPassword,
        firstName: userData.firstName,
        lastName: userData.lastName,
        countryCode: userData.countryCode,
        isOnboardingCompleted: userData.isOnboardingCompleted,
      });

      console.log(`✅ Created test user: ${user.email} (${user.id})`);

      // Create test workers for each user
      const workerCount = userData.email.includes('performance') ? 100 : 50;
      const workers = [];

      for (let i = 0; i < workerCount; i++) {
        const worker = await workersService.create(user.id, {
          name: `${userData.firstName} Worker ${i + 1}`,
          phoneNumber: `+25471234567${(i % 10).toString()}`,
          email: `worker${i + 1}@example.com`,
          salaryGross: 30000 + i * 1000, // Varying salaries
          startDate: '2024-01-01',
          jobTitle: `Position ${i + 1}`,
          employmentType: EmploymentType.FIXED,
          paymentFrequency: PaymentFrequency.MONTHLY,
          paymentMethod: i % 2 === 0 ? PaymentMethod.BANK : PaymentMethod.MPESA,
          bankName: i % 2 === 0 ? 'KCB Bank' : undefined,
          bankAccount:
            i % 2 === 0
              ? `1234567890${i.toString().padStart(3, '0')}`
              : undefined,
          mpesaNumber:
            i % 2 === 1 ? `+25471234567${(i % 10).toString()}` : undefined,
        });

        workers.push(worker);
      }

      console.log(`✅ Created ${workers.length} workers for ${user.email}`);
    }

    // Create special compliance test data
    const complianceUser = await userRepo.save({
      email: 'compliance-test@paykey.com',
      passwordHash: await bcrypt.hash('test-password', 10),
      firstName: 'Compliance',
      lastName: 'Test',
      countryCode: 'KE',
      isOnboardingCompleted: true,
    });

    // Create workers with specific salaries for tax compliance testing
    const complianceWorkers = [
      { salary: 10000, name: 'Low Salary Worker' },
      { salary: 25000, name: 'Threshold Worker' },
      { salary: 35000, name: 'Mid Range Worker' },
      { salary: 60000, name: 'High Salary Worker' },
      { salary: 120000, name: 'Very High Salary Worker' },
      { salary: 200000, name: 'Executive Worker' },
      { salary: 500000, name: 'Top Bracket Worker' },
    ];

    for (const workerData of complianceWorkers) {
      await workersService.create(complianceUser.id, {
        name: workerData.name,
        phoneNumber: '+254712345670',
        salaryGross: workerData.salary,
        startDate: '2024-01-01',
        jobTitle: 'Test Position',
        employmentType: EmploymentType.FIXED,
        paymentFrequency: PaymentFrequency.MONTHLY,
        paymentMethod: PaymentMethod.BANK,
        bankName: 'KCB Bank',
        bankAccount: '1234567890',
      });
    }

    console.log('✅ Created compliance test workers');

    console.log('🎉 Test data seeding completed successfully!');
    console.log('\n📊 Summary:');
    console.log('- 3 test users created');
    console.log('- 200 test workers created');
    console.log('- 7 compliance test workers created');
    console.log('- All with realistic Kenyan payroll data');
  } catch (error) {
    console.error('❌ Error seeding test data:', error);
    throw error;
  } finally {
    await app.close();
  }
}

seedTestData().catch(console.error);
