const { Client } = require('pg');

const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'postgres',
    password: 'admin',
    database: 'paykey',
});

async function updateSchema() {
    try {
        await client.connect();
        console.log('Connected to database');

        await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS "idType" text,
      ADD COLUMN IF NOT EXISTS "nationalityId" uuid;
    `);

        console.log('Schema updated successfully');
    } catch (err) {
        console.error('Error updating schema:', err);
    } finally {
        await client.end();
    }
}

updateSchema();
