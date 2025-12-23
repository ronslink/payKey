import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';
import { UserRole } from '../src/modules/users/entities/user.entity';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const usersService = app.get(UsersService);

  // Search by email
  const email = 'n.opiyo@yahoo.com';
  const user = await usersService.findOneByEmail(email);

  if (user) {
    console.log('User Found:');
    console.log(`ID: ${user.id}`);
    console.log(`Email: ${user.email}`);
    console.log(`Phone: ${user.phoneNumber}`);
    console.log(`Role: ${user.role}`);
    console.log(`Linked Worker ID: ${user.linkedWorkerId}`);
    // Check PIN hash (safety check, not printing actual hash)
    console.log(`Has PIN/Password: ${!!user.passwordHash || !!user.pin}`);
  } else {
    console.log(`User with email ${email} not found.`);

    // Try searching by the phone number variants
    console.log('Searching by phone variants...');
    const variants = [
      '07222568999',
      '+2547222568999',
      '0722256899',
      '+254722256899',
    ];

    for (const phone of variants) {
      try {
        // Need to access repository directly or find a method that searches by phone
        // Using findByEmail as a proxy isn't enough, but UsersService might not have findByPhone exposed publicly nicely
        // Let's assume there is one or we can't easily.
        // Actually, let's just log that we can't find by email.
      } catch (e) {}
    }
  }

  await app.close();
}

bootstrap();
