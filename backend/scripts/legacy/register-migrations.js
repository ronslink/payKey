const { Client } = require('pg');
require('dotenv').config({ path: '.env.development' });

async function registerMigrations() {
  const client = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'admin',
    database: 'paykey',
  });

  try {
    console.log('🔄 Connecting to paykey database...');
    await client.connect();
    
    console.log('📋 Registering migrations in TypeORM migrations table...');
    
    // Register the migrations that we've already applied manually
    const migrations = [
      {
        timestamp: 1732456700000,
        name: 'PaykeyInitialSchema1732456700000',
      },
      {
        timestamp: 1732467840000,
        name: 'AddIsOnboardingCompletedToUser1732467840000',
      },
      {
        timestamp: 1732468867000,
        name: 'AddResidentStatusAndCountryCode1732468867000',
      },
    ];
    
    for (const migration of migrations) {
      try {
        await client.query(
          'INSERT INTO migrations (timestamp, name) VALUES ($1, $2)',
          [migration.timestamp, migration.name]
        );
        console.log(`✅ Registered: ${migration.name}`);
      } catch (error) {
        console.log(`ℹ️ Migration may already exist: ${migration.name}`);
      }
    }
    
    // Verify registration
    const result = await client.query('SELECT timestamp, name FROM migrations ORDER BY timestamp');
    
    console.log('\n📊 Registered migrations:');
    result.rows.forEach(migration => {
      console.log(`📅 ${new Date(migration.timestamp).toISOString()}: ${migration.name}`);
    });
    
    console.log('\n🎉 Migration registration completed successfully!');
    console.log('\n💡 TypeORM will now recognize these migrations as applied.');
    console.log('🔧 Future migrations can now be run without conflicts.');
    
  } catch (error) {
    console.error('❌ Migration registration failed:', error.message);
  } finally {
    await client.end();
  }
}

registerMigrations();