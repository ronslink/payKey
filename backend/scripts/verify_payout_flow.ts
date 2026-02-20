const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('../dist/src/app.module');
const { IntaSendService } = require('../dist/src/modules/payments/intasend.service');
const { getRepositoryToken } = require('@nestjs/typeorm');
const { User } = require('../dist/src/modules/users/entities/user.entity');
const { Transaction } = require('../dist/src/modules/payments/entities/transaction.entity');

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const intaSendService = app.get(IntaSendService);
    const usersRepository = app.get(getRepositoryToken(User));
    const transactionRepository = app.get(getRepositoryToken(Transaction));

    console.log('--- Verifying IntaSend Payout (B2C) Flow ---');

    // 1. Fetch Test User
    const user = await usersRepository.findOne({ where: { email: 'testuser@paykey.com' } });
    if (!user) {
        console.error('❌ Test user not found!');
        process.exit(1);
    }

    console.log(`User found: ${user.email}`);
    console.log(`Wallet ID: ${user.intasendWalletId}`);

    if (!user.intasendWalletId) {
        console.warn('⚠️ User has no wallet ID. Payout will fail for wallet-linked transfers.');
    }

    // 2. Create Pending Transaction (Withdrawal)
    const amount = 777; // Magic amount to trigger simulation
    const phoneNumber = '254712345678';

    const newTx = transactionRepository.create({
        userId: user.id,
        amount: amount,
        currency: 'KES',
        type: 'SALARY_PAYOUT', // TransactionType.SALARY_PAYOUT
        status: 'PENDING',
        walletId: user.intasendWalletId,
        description: 'Test Payout',
        provider: 'INTASEND',
        recipientPhone: phoneNumber,
        accountReference: `Payout-${user.id}-${Date.now()}`,
        metadata: {
            initiatedAt: new Date().toISOString(),
        }
    });

    const savedTx = await transactionRepository.save(newTx);
    console.log(`Created Pending Transaction: ${savedTx.id}`);

    // 3. Initiate Payout
    try {
        console.log(`Initiating Payout for ${amount} KES to ${phoneNumber}...`);

        const payload = [{
            account: phoneNumber,
            amount: amount,
            narrative: 'Test Payout',
            name: 'Test User'
        }];

        const result = await intaSendService.sendMoney(payload, user.intasendWalletId);
        console.log('✅ Payout Initiated Successfully:', result);

        // Update provider ref from result (tracking_id)
        if (result.tracking_id) {
            savedTx.providerRef = result.tracking_id;
            await transactionRepository.save(savedTx);
            console.log(`Updated Transaction with Provider Ref: ${savedTx.providerRef}`);
        } else {
            console.warn('⚠️ No tracking_id in response:', result);
        }

    } catch (error) {
        console.error('❌ Payout Failed:', error.message);
        if (error.response) {
            console.error('Response Data:', error.response.data);
        }
    }

    await app.close();
}

bootstrap();
