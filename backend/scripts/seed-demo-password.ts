import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../src/modules/users/entities/user.entity';

async function updateDemoPassword() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  const userRepository = dataSource.getRepository(User);
  const demoUser = await userRepository.findOne({
    where: { email: 'testuser@paykey.com' },
  });

  if (!demoUser) {
    console.log('Demo user not found');
    return;
  }

  const salt = await bcrypt.genSalt();
  const hashedPassword = await bcrypt.hash('testuser123', salt);

  demoUser.passwordHash = hashedPassword;
  await userRepository.save(demoUser);

  console.log('Demo user password updated successfully');
  await app.close();
}

updateDemoPassword().catch(console.error);
