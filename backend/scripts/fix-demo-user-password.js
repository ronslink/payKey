const bcrypt = require('bcrypt');
const { Pool } = require('pg');

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'paykey',
  user: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
});

async function fixDemoUserPassword() {
  try {
    // Generate a new bcrypt hash for "testuser123"
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash('testuser123', saltRounds);
    
    console.log('Generated password hash:', passwordHash);
    
    // Update the demo user password
    const result = await pool.query(
      'UPDATE users SET "passwordHash" = $1 WHERE email = $2 RETURNING id, email',
      [passwordHash, 'testuser@paykey.com']
    );
    
    if (result.rowCount > 0) {
      console.log('✅ Demo user password updated successfully!');
      console.log('User:', result.rows[0]);
    } else {
      console.log('❌ Demo user not found');
    }
  } catch (error) {
    console.error('❌ Error updating password:', error);
  } finally {
    await pool.end();
  }
}

fixDemoUserPassword();
