
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'db',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'paykey',
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
});

async function setPlatinumRaw() {
    try {
        const email = 'testuser@paykey.com';
        console.log(`Setting ${email} to PLATINUM (Raw SQL)...`);

        const res = await pool.query(
            `UPDATE users SET tier = 'PLATINUM' WHERE email = $1 RETURNING id, email, tier`,
            [email]
        );

        if (res.rowCount > 0) {
            console.log('✅ Update successful:', res.rows[0]);
        } else {
            console.log('❌ User not found');
        }

    } catch (err) {
        console.error('❌ Error:', err);
    } finally {
        await pool.end();
    }
}

setPlatinumRaw();
