const { Pool } = require('pg');

async function resetPassword() {
    const email = 'testuser@paykey.com';
    const hashedPassword = '$2b$10$fBwCw/exg4..1gTPcNR0OeWLDoVgXB298.0XKzIwY7/thKy2HJjBu'; // Hash for testuser123
    const dbUrl = process.env.DATABASE_URL;

    if (!dbUrl) {
        console.error('❌ Error: DATABASE_URL environment variable is not set.');
        process.exit(1);
    }

    console.log(`🔐 Resetting password for ${email} in production...`);

    const pool = new Pool({
        connectionString: dbUrl,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        const query = 'UPDATE users SET "passwordHash" = $1 WHERE email = $2';
        const res = await pool.query(query, [hashedPassword, email]);

        if (res.rowCount > 0) {
            console.log('✅ Password updated successfully!');
        } else {
            console.log('⚠️  User not found.');
        }
    } catch (err) {
        console.error('❌ Database error:', err.message);
    } finally {
        await pool.end();
    }
}

resetPassword();
