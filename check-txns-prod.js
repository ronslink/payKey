const { DataSource } = require('typeorm');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [], // No entities needed for raw query
    synchronize: false,
    ssl: { rejectUnauthorized: false },
});

async function checkRecentTransactions() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database (Raw Mode)');

        // Raw SQL query
        // Note: Transaction entity does not have updatedAt column!
        const transactions = await AppDataSource.query(
            `SELECT * FROM transactions ORDER BY "createdAt" DESC LIMIT 20`
        );

        console.log('\n--- Recent Updated Transactions ---');
        if (transactions.length > 0) {
            console.log('Sample Keys:', Object.keys(transactions[0]).join(', '));
        }

        transactions.forEach(tx => {
            console.log(`\nID: ${tx.id}`);
            console.log(`Type: ${tx.type}`);
            console.log(`Status: ${tx.status}`);
            console.log(`Amount: ${tx.amount} ${tx.currency}`);
            console.log(`Provider Ref: ${tx.providerRef}`);
            console.log(`Account Ref: ${tx.accountReference}`);
            console.log(`Updated At: ${tx.updatedAt}`);
            if (tx.metadata) console.log('Metadata:', JSON.stringify(tx.metadata));
        });

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkRecentTransactions();
