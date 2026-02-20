const { DataSource } = require('typeorm');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [],
    synchronize: false,
    ssl: { rejectUnauthorized: false },
});

async function listAllWallets() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database (Raw Mode)');

        // We suspect column name might be snake_case or similar. 
        // We'll fetch all users and filter in JS to be safe.
        // But for performance, let's try a broad select.
        const users = await AppDataSource.query(
            `SELECT * FROM users`
        );

        // Filter for users with wallet ID (check various possible keys)
        const activeUsers = users.filter(u => u.intasendWalletId || u.intasend_wallet_id || u.walletId);

        console.log(`\nFound ${activeUsers.length} active wallet user(s):`);

        const formatMoney = (amount) => {
            return parseFloat(amount || 0).toFixed(2);
        };

        for (const user of activeUsers) {
            const walletId = user.intasendWalletId || user.intasend_wallet_id || user.walletId;
            const balance = user.walletBalance || user.wallet_balance || 0;
            const clearing = user.clearingBalance || user.clearing_balance || 0;
            const name = `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email;
            const business = user.businessName || 'N/A';

            console.log(`\nUser: ${name} (${user.email})`);
            console.log(`  Business: ${business}`);
            console.log(`  Wallet ID: ${walletId}`);
            console.log(`  Balance: KES ${formatMoney(balance)}`);
            console.log(`  Clearing: KES ${formatMoney(clearing)}`);
            console.log(`  Last Updated: ${user.updatedAt || user.updated_at}`);
        }

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

listAllWallets();
