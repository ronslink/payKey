
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import { Transaction } from './src/modules/payments/entities/transaction.entity';

dotenv.config();

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [Transaction],
    synchronize: false,
});

async function checkRecentTransactions() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database');

        const transactionRepo = AppDataSource.getRepository(Transaction);

        // Get last 5 transactions
        const transactions = await transactionRepo.find({
            order: { createdAt: 'DESC' },
            take: 5,
        });

        console.log('\n--- Recent Transactions ---');
        for (const tx of transactions) {
            console.log(`\nID: ${tx.id}`);
            console.log(`Type: ${tx.type}`);
            console.log(`Status: ${tx.status}`);
            console.log(`Amount: ${tx.amount} ${tx.currency}`);
            console.log(`Provider Ref: ${tx.providerRef}`);
            console.log(`Created At: ${tx.createdAt}`);

            if (tx.metadata) {
                console.log('Metadata:', JSON.stringify(tx.metadata, null, 2));
            }
        }

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkRecentTransactions();
