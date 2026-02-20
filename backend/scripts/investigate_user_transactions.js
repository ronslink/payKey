const { DataSource } = require('typeorm');
// require('dotenv').config({ path: '../.env' });
// require('dotenv').config();

console.log('Database URL:', process.env.DATABASE_URL ? 'Set' : 'Not Set');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5435'),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'admin',
    database: process.env.DB_NAME || 'paykey',
    entities: [],
    synchronize: false,
    ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

async function investigate() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database');

        const searchName = 'Evans Onyango';
        const searchEmail = 'e.ochieng.onyango@gmail.com';

        console.log(`Searching for user: Name="${searchName}" OR Email="${searchEmail}"`);

        const users = await AppDataSource.query(
            `SELECT * FROM users WHERE "email" ILIKE $1 OR "firstName" ILIKE $2 OR "lastName" ILIKE $3`,
            [searchEmail, '%Evans%', '%Onyango%']
        );

        if (users.length === 0) {
            console.log('User not found.');
            await AppDataSource.destroy();
            return;
        }

        for (const user of users) {
            console.log(`\n---------------------------------------------------`);
            console.log(`User Found: ${user.firstName} ${user.lastName}`);
            console.log(`ID: ${user.id}`);
            console.log(`Email: ${user.email}`);
            console.log(`Wallet Balance: ${user.walletBalance}`);
            console.log(`Clearing Balance: ${user.clearingBalance}`);
            console.log(`IntaSend Wallet ID: ${user.intasendWalletId}`);

            const txns = await AppDataSource.query(
                `SELECT * FROM transactions WHERE "userId" = $1 ORDER BY "createdAt" DESC LIMIT 20`,
                [user.id]
            );

            console.log(`\nRecent Transactions (${txns.length}):`);
            if (txns.length > 0) {
                console.log('ID | Type | Status | Amount | Created At | Provider Ref');
                console.log('-'.repeat(80));
                txns.forEach(tx => {
                    console.log(`${tx.id} | ${tx.type} | ${tx.status} | ${tx.amount} ${tx.currency} | ${tx.createdAt} | ${tx.providerRef}`);
                    if (tx.metadata) {
                        console.log('Metadata:', JSON.stringify(tx.metadata, null, 2));
                    }
                });
            } else {
                console.log('No transactions found.');
            }
            console.log(`---------------------------------------------------\n`);

            // Check Workers
            const workers = await AppDataSource.query(
                `SELECT * FROM workers WHERE "userId" = $1`,
                [user.id]
            );
            console.log(`Workers Found (${workers.length}):`);
            workers.forEach(w => {
                console.log(`- ${w.firstName} ${w.lastName} (ID: ${w.id})`);
                console.log(`  Phone: ${w.phoneNumber} | Mpesa: ${w.mpesaNumber} | Bank: ${w.bankAccount} (${w.bankCode})`);
                console.log(`  Payment Method: ${w.paymentMethod} | IsActive: ${w.isActive}`);
            });

            // Check Payroll Records (Last 5)
            const payrolls = await AppDataSource.query(
                `SELECT * FROM payroll_records WHERE "userId" = $1 ORDER BY "createdAt" DESC LIMIT 5`,
                [user.id]
            );
            console.log(`\nRecent Payroll Records (${payrolls.length}):`);

            for (const p of payrolls) {
                console.log(`- ID: ${p.id}`);
                console.log(`  WorkerID: ${p.workerId}`);
                console.log(`  Status: ${p.status} | PaymentStatus: ${p.paymentStatus}`);
                console.log(`  Gross: ${p.grossSalary} | Tax: ${p.taxAmount} | Bonuses: ${p.bonuses}`);
                console.log(`  OtherDeductions: ${p.otherDeductions} | NetSalary: ${p.netSalary}`);
                if (p.deductions) console.log(`  Deductions JSON: ${JSON.stringify(p.deductions)}`);
                console.log(`  Created: ${p.createdAt}`);

                // Check for linked transaction
                const txns = await AppDataSource.query(
                    `SELECT * FROM transactions WHERE metadata->>'payrollRecordId' = $1`,
                    [p.id]
                );
                if (txns.length > 0) {
                    txns.forEach(tx => {
                        console.log(`  -> LINKED TX: ${tx.id} | Status: ${tx.status} | ProviderRef: ${tx.providerRef}`);
                    });
                } else {
                    console.log(`  -> NO LINKED TRANSACTION FOUND`);
                }
                console.log(''); // Empty line for readability
            }

        }

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error during investigation:', error);
        process.exit(1);
    }
}

investigate();
