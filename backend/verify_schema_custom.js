
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Load env
const envPath = path.join(__dirname, '.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) env[key.trim()] = value.trim();
});

const client = new Client({
    host: env.DB_HOST || 'localhost',
    port: parseInt(env.DB_PORT || '5432'),
    user: env.DB_USERNAME || 'postgres',
    password: env.DB_PASSWORD || 'admin',
    database: env.DB_NAME || 'paykey',
});

async function checkSchema() {
    try {
        await client.connect();
        console.log('Connected to database');

        // Get all tables
        const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);

        const tables = res.rows.map(r => r.table_name);
        console.log('Found tables:', tables);

        // Expected entities based on file exploration (using plural names found in entities)
        const expectedTables = [
            'users', 'workers', 'pay_periods', 'payroll_records',
            'transactions', 'tax_tables', 'tax_submissions',
            'tax_payments', 'tax_configs', 'subscriptions',
            'subscription_payments', 'properties', 'countries',
            'leave_requests', 'terminations', 'account_mappings',
            'accounting_exports'
        ];

        const missing = expectedTables.filter(e => !tables.includes(e));
        if (missing.length > 0) {
            console.log('MISSING TABLES (Confirmed):', missing);
        } else {
            console.log('All expected tables found.');
        }

        // Check columns for 'users' table
        if (tables.includes('users')) {
            const userCols = await client.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'users'
      `);
            const columns = userCols.rows.map(r => r.column_name);
            console.log('Users table columns:', columns);

            const requiredCols = ['stripeCustomerId', 'kraPin', 'nssfNumber', 'nhifNumber'];
            // Note: Postgres columns are usually lowercase, but TypeORM might quote them. 
            // Let's check case-insensitively or just print them.
            const missingCols = requiredCols.filter(c => !columns.includes(c) && !columns.includes(c.toLowerCase()) && !columns.includes(c.replace(/[A-Z]/g, m => '_' + m.toLowerCase())));
            if (missingCols.length > 0) {
                console.log('MISSING COLUMNS in users:', missingCols);
            }
        }

    } catch (err) {
        console.error('Database error:', err);
    } finally {
        await client.end();
    }
}

checkSchema();
