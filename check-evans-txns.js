const { DataSource } = require('typeorm');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [],
    synchronize: false,
    ssl: { rejectUnauthorized: false },
});

async function checkEvansTxns() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database');

        const email = 'e.ochieng.onyango@gmail.com';

        const users = await AppDataSource.query(
            `SELECT * FROM users WHERE "email" ILIKE $1`,
            [email]
        );

        if (users.length === 0) {
            console.log('User not found');
            return;
        }

        const user = users[0];
        console.log(`User: ${user.firstName} ${user.lastName} (${user.id})`);
        console.log(`Balances: Wallet ${user.walletBalance}, Clearing ${user.clearingBalance}`);

        const txns = await AppDataSource.query(
            `SELECT * FROM transactions WHERE "userId" = $1 ORDER BY "createdAt" DESC LIMIT 10`,
            [user.id]
        );

        console.log('\nRecent Transactions:');
        txns.forEach(tx => {
            console.log(`ID: ${tx.id} | Amount: ${tx.amount} ${tx.currency} | Type: ${tx.type} | Status: ${tx.status} | Created: ${tx.createdAt}`);
        });

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkEvansTxns();
