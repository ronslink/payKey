const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  port: 5432,
});

async function checkUsers() {
  try {
    await client.connect();
    console.log('Connected to database');
    
    const result = await client.query('SELECT id, email FROM users ORDER BY "createdAt"');
    console.log('Existing users:');
    result.rows.forEach(user => {
      console.log(`- ${user.email} (ID: ${user.id})`);
    });
    
  } catch (error) {
    console.error('Database connection error:', error);
  } finally {
    await client.end();
  }
}

checkUsers();
