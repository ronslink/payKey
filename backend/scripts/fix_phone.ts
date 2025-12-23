import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { Repository } from 'typeorm';

async function bootstrap() {
  // Disable logging to keep output clean, handling potential DB connection errors gracefully
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn'],
  });

  const usersRepository = app.get<Repository<User>>(getRepositoryToken(User));
  const workersRepository = app.get<Repository<Worker>>(
    getRepositoryToken(Worker),
  );

  const email = 'n.opiyo@yahoo.com';
  console.log(`Searching for user with email: ${email}`);

  const user = await usersRepository.findOne({ where: { email } });

  if (user) {
    console.log(`Found USER. Current Phone: '${user.phoneNumber}'`);

    // Correct phone number: remove last digit if it's the 11-digit typo version, or just set to known good.
    // User provided: 07222568999 (11 digits) -> convert to +254...
    // Correct: 0722256899 (10 digits) -> +254722256899

    const correctPhone = '+254722256899';

    if (user.phoneNumber !== correctPhone) {
      user.phoneNumber = correctPhone;
      await usersRepository.save(user);
      console.log(`✅ Updated USER phone to: ${correctPhone}`);
    } else {
      console.log(`User phone is already correct: ${correctPhone}`);
    }

    // Also check linked worker
    if (user.linkedWorkerId) {
      const worker = await workersRepository.findOne({
        where: { id: user.linkedWorkerId },
      });
      if (worker) {
        console.log(
          `Found linked WORKER. Current Phone: '${worker.phoneNumber}'`,
        );
        if (worker.phoneNumber !== correctPhone) {
          worker.phoneNumber = correctPhone;
          await workersRepository.save(worker);
          console.log(`✅ Updated WORKER phone to: ${correctPhone}`);
        } else {
          console.log(`Worker phone is already correct.`);
        }
      } else {
        console.log(
          'Linked worker ID found on user, but worker record not found.',
        );
      }
    } else {
      console.log('User has no linked worker ID.');
    }
  } else {
    console.log(`❌ User with email ${email} NOT FOUND.`);

    // OPTIONAL: Force search in workers table directly if user account doesn't exist yet
    // This handles the case where they are claiming the account and the User record doesn't exist,
    // but the Worker record has the bad phone number preventing the claim.
    console.log('Searching in WORKERS table by email...');
    const worker = await workersRepository.findOne({ where: { email } });
    if (worker) {
      console.log(
        `Found WORKER (no user account yet?). Current Phone: '${worker.phoneNumber}'`,
      );
      const correctPhone = '+254722256899'; // Standardized
      if (worker.phoneNumber !== correctPhone) {
        worker.phoneNumber = correctPhone;
        await workersRepository.save(worker);
        console.log(`✅ Updated WORKER phone to: ${correctPhone}`);
      } else {
        console.log(`Worker phone already correct.`);
      }
    } else {
      console.log(`❌ Worker with email ${email} NOT FOUND either.`);
    }
  }

  await app.close();
  process.exit(0);
}

bootstrap().catch((err) => {
  console.error(err);
  process.exit(1);
});
