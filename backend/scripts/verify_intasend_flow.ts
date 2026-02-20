const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('../dist/src/app.module');
const { IntaSendService } = require('../dist/src/modules/payments/intasend.service');
const { getRepositoryToken } = require('@nestjs/typeorm');
const { User } = require('../dist/src/modules/users/entities/user.entity');

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const intaSendService = app.get(IntaSendService);
    const usersRepository = app.get(getRepositoryToken(User));

    console.log('--- Verifying IntaSend STK Push with Wallet ID ---');

    // 1. Fetch Test User
    const user = await usersRepository.findOne({ where: { email: 'testuser@paykey.com' } });
    if (!user) {
        console.error('❌ Test user not found!');
        process.exit(1);
    }

    console.log(`User found: ${user.email}`);
    console.log(`Wallet ID: ${user.intasendWalletId}`);

    if (!user.intasendWalletId) {
        console.warn('⚠️ User has no wallet ID. STK Push will go to master wallet.');
    }

    // 2. Create Pending Transaction
    const { Transaction } = require('../dist/src/modules/payments/entities/transaction.entity');
    const transactionRepository = app.get(getRepositoryToken(Transaction));

    const amount = 10;
    const phoneNumber = '254712345678'; // Test phone number

    const newTx = transactionRepository.create({
        userId: user.id,
        amount: amount,
        currency: 'KES',
        type: 'DEPOSIT', // TransactionType.DEPOSIT
        status: 'PENDING', // TransactionStatus.PENDING
        walletId: user.intasendWalletId,
        description: 'Test STK Push',
        provider: 'INTASEND',
        recipientPhone: phoneNumber,
        accountReference: `TopUp-${user.id}-${Date.now()}`,
        metadata: {
            initiatedAt: new Date().toISOString(),
        }
    });

    const savedTx = await transactionRepository.save(newTx);
    console.log(`Created Pending Transaction: ${savedTx.id}`);

    // 3. Initiate STK Push
    try {
        console.log(`Initiating STK Push for ${amount} KES to ${phoneNumber}...`);
        // Use Transaction ID as api_ref so webhook can find it
        const result = await intaSendService.initiateStkPush(
            phoneNumber,
            amount,
            savedTx.id,
            user.intasendWalletId
        );
        console.log('✅ STK Push Initiated Successfully:', result);

        // Update provider ref from result
        savedTx.providerRef = result.invoice?.invoice_id || result.id || result.tracking_id;
        await transactionRepository.save(savedTx);
        console.log(`Updated Transaction with Provider Ref: ${savedTx.providerRef}`);

    } catch (error) {
        console.error('❌ STK Push Failed:', error.message);
        if (error.response) {
            console.error('Response Data:', error.response.data);
        }
    }

    await app.close();
}

bootstrap();
