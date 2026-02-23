import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole, UserTier } from '../src/modules/users/entities/user.entity';

const ADMIN_EMAIL = 'admin@paydome.io';
const ADMIN_PASSWORD = 'PayDome@Admin2024!';

async function seedAdmin() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  const userRepository = dataSource.getRepository(User);

  // Check if admin user exists
  let adminUser = await userRepository.findOne({
    where: { email: ADMIN_EMAIL },
  });

  const salt = await bcrypt.genSalt();
  const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, salt);

  if (adminUser) {
    // Update existing admin user
    adminUser.passwordHash = hashedPassword;
    adminUser.role = UserRole.SUPER_ADMIN;
    adminUser.firstName = 'Admin';
    adminUser.lastName = 'User';
    await userRepository.save(adminUser);
    console.log('Admin user updated successfully');
  } else {
    // Create new admin user
    adminUser = userRepository.create({
      email: ADMIN_EMAIL,
      passwordHash: hashedPassword,
      role: UserRole.SUPER_ADMIN,
      firstName: 'Admin',
      lastName: 'User',
      tier: UserTier.PLATINUM,
      isOnboardingCompleted: true,
    });
    await userRepository.save(adminUser);
    console.log('Admin user created successfully');
  }

  console.log(`Admin credentials:`);
  console.log(`  Email: ${ADMIN_EMAIL}`);
  console.log(`  Password: ${ADMIN_PASSWORD}`);

  await app.close();
}

seedAdmin().catch(console.error);
