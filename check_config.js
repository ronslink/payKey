const { Client } = require('pg');

const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function run() {
    try {
        await client.connect();
        console.log('Connected to DB');

        const res = await client.query('SELECT * FROM system_config');
        if (res.rows.length === 0) {
            console.log('⚠️  Table system_config is EMPTY');
        } else {
            console.table(res.rows);
        }

        await client.end();
    } catch (e) {
        if (e.code === '42P01') {
            console.error('❌ Table system_config DOES NOT EXIST');
        } else {
            console.error('❌ Error:', e);
        }
        client.end();
        process.exit(1);
    }
}

run();
