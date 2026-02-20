const { DataSource } = require('typeorm');
// require('dotenv').config(); // Not needed in prod container

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [
        require('../dist/src/modules/users/entities/user.entity').User,
        require('../dist/src/modules/payments/entities/transaction.entity').Transaction,
        require('../dist/src/modules/workers/entities/worker.entity').Worker,
        require('../dist/src/modules/payroll/entities/pay-period.entity').PayPeriod,
    ],
    synchronize: false,
    ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

async function fix() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database');

        const txRepo = AppDataSource.getRepository('Transaction');
        const userRepo = AppDataSource.getRepository('User');

        // 1. Fix KZ5MM24 (7 days old, stuck in manual clearing)
        const ref = 'KZ5MM24';
        const tx = await txRepo.findOne({ where: { providerRef: ref } });

        if (!tx) {
            console.log(`Transaction ${ref} not found`);
            return;
        }

        console.log(`Transaction ${ref} found: Status=${tx.status}, Amount=${tx.amount}, User=${tx.userId}`);

        if (tx.status === 'CLEARING') {
            console.log('Updating status to SUCCESS...');
            tx.status = 'SUCCESS';
            await txRepo.save(tx);

            const user = await userRepo.findOne({ where: { id: tx.userId } });
            console.log(`User before: Wallet=${user.walletBalance}, Clearing=${user.clearingBalance}`);

            user.walletBalance = Number(user.walletBalance) + Number(tx.amount);
            user.clearingBalance = Number(user.clearingBalance) - Number(tx.amount);

            // Safety check
            if (user.clearingBalance < 0) {
                console.warn('Warning: Clearing balance going negative. Setting to 0.');
                user.clearingBalance = 0;
            }

            await userRepo.save(user);
            console.log(`User after:  Wallet=${user.walletBalance}, Clearing=${user.clearingBalance}`);
            console.log('Fix applied successfully.');
        } else {
            console.log(`Transaction is already ${tx.status}, no action needed.`);
        }

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        Process.exit(1);
    }
}

fix();
