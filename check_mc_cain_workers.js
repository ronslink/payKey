const { Client } = require('pg');

const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function run() {
    try {
        await client.connect();
        const res = await client.query(`
            SELECT id, name, "phoneNumber", "isActive", "createdAt", "userId"
            FROM workers
            WHERE name ILIKE '%Mc cain%'
            ORDER BY "createdAt" DESC
        `);
        console.log(`Found ${res.rowCount} workers with name like 'Mc cain'`);
        console.log(JSON.stringify(res.rows, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        await client.end();
    }
}

run();
