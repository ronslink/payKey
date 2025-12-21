
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User } from './src/modules/users/entities/user.entity';
import { Repository } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
    const usersRepository = app.get<Repository<User>>(getRepositoryToken(User));

    const email = 'n.opiyo@yahoo.com';
    const user = await usersRepository.findOne({ where: { email } });

    if (user) {
        console.log(`VERIFICATION_RESULT: ${user.phoneNumber}`);
    } else {
        console.log('VERIFICATION_RESULT: USER_NOT_FOUND');
    }

    await app.close();
    process.exit(0);
}

bootstrap().catch(() => process.exit(1));
