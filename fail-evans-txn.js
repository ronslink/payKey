const { DataSource } = require('typeorm');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [],
    synchronize: false,
    ssl: { rejectUnauthorized: false },
});

async function failTxn() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database');

        const txnId = '4bb3e160-eb45-4e55-be52-891acc1d9422';

        // Update status to FAILED
        // Note: transactions table DOES NOT have updatedAt column.
        const result = await AppDataSource.query(
            `UPDATE transactions SET status = 'FAILED' WHERE id = $1 RETURNING id, status, amount, type`,
            [txnId]
        );

        console.log('Update Result:', result);

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

failTxn();
