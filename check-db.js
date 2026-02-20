
const { Client } = require('pg');

// Parse DATABASE_URL if available, or construct from env
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    console.error('DATABASE_URL environment variable is not set.');
    process.exit(1);
}

const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false } // Managed DBs often need this if not using CA cert
});

async function checkTables() {
    try {
        await client.connect();
        console.log('Connected to database successfully.');

        const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);

        console.log('--- Tables in Database ---');
        res.rows.forEach(row => console.log(row.table_name));

        // Check migrations specifically
        const migrations = await client.query('SELECT name, timestamp FROM migrations ORDER BY timestamp DESC LIMIT 5');
        console.log('\n--- Recent Migrations ---');
        migrations.rows.forEach(m => console.log(`${new Date(Number(m.timestamp)).toISOString()} - ${m.name}`));

        await client.end();
    } catch (err) {
        console.error('Database connection error:', err);
        process.exit(1);
    }
}

checkTables();
