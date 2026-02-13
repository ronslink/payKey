
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { UsersService } from '../modules/users/users.service';
import { IntaSendService } from '../modules/payments/intasend.service';
import { Logger } from '@nestjs/common';
import { User } from '../modules/users/entities/user.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const logger = new Logger('BackfillWallets');

    const usersService = app.get(UsersService);
    const intaSendService = app.get(IntaSendService);

    logger.log('🚀 Starting Wallet Backfill Script...');

    // 1. Get all users
    // Note: usersService doesn't have a findAll method exposed directly that returns everything we need?
    // We might need to access the repository directly or add a method.
    // For script simplicity, let's just use the repository if we can, or add a finder.
    // Actually, we can just use TypeORM repository if we get it from module, but let's try to stick to service if possible.
    // Since we don't have a "findAll", we'll use the repository injection pattern if possible, 
    // but better to just use the module's repository if exported or add a temp method?
    // Let's assume we can get the repository from the app context if it's exported, OR just add a "findAll" to service.
    // Modifying the service might be cleaner for future use.

    // Let's use the repository directly via getRepositoryToken logic or just add a helper to UsersService.
    // Checking UsersService... it has findOneBy... but no findAll.
    // I will add a `findAllOnboardedWithoutWallet` method to UsersService first? 
    // No, I'll just use the repository directly since I can get it from the container 
    // using `getRepositoryToken(User)`.

    const repo = app.get<any>('UserRepository'); // Default token is usually 'UserRepository' or similar if custom,
    // BUT TypeORM usually uses getRepositoryToken(User).
    // Let's rely on adding a method to UsersService to be safe and clean.

    logger.log('Fetching users without wallets...');

    // We need to implement this search in the script or service. 
    // Let's assume we can add a method to UsersService. 
    // But I don't want to modify the service just for a one-off script if I can avoid it.
    // Let's try to get the repository from the module.

    // Actually, let's just make the script robust.
    // We'll trust that we can access the repository if we import `getRepositoryToken`.

}

// Rewriting to include the repository access properly
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';

async function run() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const logger = new Logger('BackfillWallets');

    try {
        const userRepository = app.get<Repository<User>>(getRepositoryToken(User));
