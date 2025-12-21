const { Pool } = require('pg');
require('dotenv').config({ path: '.env.development' });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  database: process.env.DB_NAME || 'paykey',
});

async function updatePassword() {
  try {
    console.log('🔄 Updating demo user password...');
    
    const hashedPassword = '$2b$10$fBwCw/exg4..1gTPcNR0OeWLDoVgXB298.0XKzIwY7/thKy2HJjBu';
    
    const result = await pool.query(
      'UPDATE users SET "passwordHash" = $1 WHERE email = $2 RETURNING id, email',
      [hashedPassword, 'testuser@paykey.com']
    );
    
    if (result.rowCount > 0) {
      console.log('✅ Password updated successfully for:', result.rows[0].email);
      console.log('📧 Email: testuser@paykey.com');
      console.log('🔑 Password: testuser123');
    } else {
      console.log('⚠️  No user found with email: testuser@paykey.com');
    }
  } catch (error) {
    console.error('❌ Error updating password:', error.message);
  } finally {
    await pool.end();
  }
}

updatePassword();
