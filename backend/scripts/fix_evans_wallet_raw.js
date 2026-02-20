const { DataSource } = require('typeorm');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [], // No entities needed for raw SQL
    synchronize: false,
    ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

async function fix() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database');

        const ref = 'KZ5MM24';

        // 1. Find Transaction
        const txns = await AppDataSource.query(
            `SELECT * FROM transactions WHERE "providerRef" = $1 LIMIT 1`,
            [ref]
        );

        if (txns.length === 0) {
            console.log(`Transaction ${ref} not found`);
            return;
        }

        const tx = txns[0];
        console.log(`Transaction ${ref} found: Status=${tx.status}, Amount=${tx.amount}, User=${tx.userId}`);

        if (tx.status === 'CLEARING') {
            console.log('Updating status to SUCCESS...');

            // 2. Update Transaction Status
            await AppDataSource.query(
                `UPDATE transactions SET status = 'SUCCESS' WHERE id = $1`,
                [tx.id]
            );

            // 3. Update User Balance
            // Fetch latest user balance first to be safe
            const users = await AppDataSource.query(
                `SELECT * FROM users WHERE id = $1`,
                [tx.userId]
            );

            if (users.length === 0) {
                console.error('User not found!');
                return;
            }

            const user = users[0];
            console.log(`User before: Wallet=${user.walletBalance}, Clearing=${user.clearingBalance}`);

            const newWalletBalance = Number(user.walletBalance) + Number(tx.amount);
            let newClearingBalance = Number(user.clearingBalance) - Number(tx.amount);

            if (newClearingBalance < 0) {
                console.warn(`Warning: Clearing balance going negative (${newClearingBalance}). Setting to 0.`);
                newClearingBalance = 0;
            }

            await AppDataSource.query(
                `UPDATE users SET "walletBalance" = $1, "clearingBalance" = $2 WHERE id = $3`,
                [newWalletBalance, newClearingBalance, user.id]
            );

            console.log(`User after:  Wallet=${newWalletBalance}, Clearing=${newClearingBalance}`);
            console.log('Fix applied successfully.');
        } else {
            console.log(`Transaction is already ${tx.status}, no action needed.`);
        }

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

fix();
