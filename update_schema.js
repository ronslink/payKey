const { Client } = require('pg');

const client = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'admin',
    database: process.env.DB_NAME || 'paykey',
});

async function updateSchema() {
    try {
        await client.connect();
        console.log('Connected to database');

        // Add missing columns to subscriptions table
        console.log('Adding subscription columns...');
        await client.query(`
            ALTER TABLE subscriptions
            ADD COLUMN IF NOT EXISTS "billingPeriod" VARCHAR DEFAULT 'monthly',
            ADD COLUMN IF NOT EXISTS "autoRenewal" BOOLEAN DEFAULT true,
            ADD COLUMN IF NOT EXISTS "pendingTier" VARCHAR,
            ADD COLUMN IF NOT EXISTS "gracePeriodEndDate" TIMESTAMP WITH TIME ZONE,
            ADD COLUMN IF NOT EXISTS "lockedPrice" DECIMAL(10, 2),
            ADD COLUMN IF NOT EXISTS "renewalMethod" VARCHAR DEFAULT 'NOTIFICATION'
        `);

        // Add missing columns to transactions table
        console.log('Adding transaction columns...');
        await client.query(`
            ALTER TABLE transactions
            ADD COLUMN IF NOT EXISTS "provider" VARCHAR,
            ADD COLUMN IF NOT EXISTS "paymentMethod" VARCHAR,
            ADD COLUMN IF NOT EXISTS "recipientPhone" VARCHAR,
            ADD COLUMN IF NOT EXISTS "accountReference" VARCHAR
        `);

        // Add payroll record improvements
        console.log('Adding payroll record columns...');
        await client.query(`
            ALTER TABLE payroll_records
            ADD COLUMN IF NOT EXISTS "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL,
            ADD COLUMN IF NOT EXISTS "bonuses" DECIMAL(10, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS "otherEarnings" DECIMAL(10, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS "otherDeductions" DECIMAL(10, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS "holidayHours" DECIMAL(10, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS "sundayHours" DECIMAL(10, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS "overtimePay" DECIMAL(10, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS "finalizedAt" TIMESTAMP WITH TIME ZONE
        `);

        // Create gov_submissions table if it doesn't exist
        console.log('Creating gov_submissions table...');
        await client.query(`
            CREATE TABLE IF NOT EXISTS gov_submissions (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                type VARCHAR NOT NULL,
                period VARCHAR,
                amount DECIMAL(12, 2),
                "referenceNumber" VARCHAR,
                status VARCHAR DEFAULT 'PENDING',
                response JSONB,
                "submittedAt" TIMESTAMP WITH TIME ZONE,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Create indexes for gov_submissions
        console.log('Creating gov_submissions indexes...');
        await client.query(`
            CREATE INDEX IF NOT EXISTS "IDX_gov_submissions_userId" ON gov_submissions("userId");
            CREATE INDEX IF NOT EXISTS "IDX_gov_submissions_type" ON gov_submissions(type)
        `);

        console.log('Schema updated successfully');
    } catch (err) {
        console.error('Error updating schema:', err);
    } finally {
        await client.end();
    }
}

updateSchema();
