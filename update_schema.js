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

        // Add idType column
        // First check if enum type exists, if not create it (optional, or just use text)
        // But TypeORM with enum usually expects the column to be of that enum type.
        // Let's try to add it as text first, usually works if we don't enforce strict enum in DB.
        // Actually, let's look at how UserRole is defined.

        // We'll just add columns.
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
