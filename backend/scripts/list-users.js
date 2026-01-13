
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'db',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'paykey',
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
});

async function listUsers() {
    try {
        const res = await pool.query('SELECT id, email, "firstName", "lastName", role FROM users');
        console.table(res.rows);
    } catch (err) {
        console.error(err);
    } finally {
        await pool.end();
    }
}

listUsers();
