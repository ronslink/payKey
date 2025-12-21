const { DataSource } = require('typeorm');
const path = require('path');
require('dotenv').config({ path: '.env.development' });

// Import migration classes
const AddIsOnboardingCompletedToUser1732467840000 = require('./src/migrations/1732467840000-AddIsOnboardingCompletedToUser').AddIsOnboardingCompletedToUser1732467840000;
const AddResidentStatusAndCountryCode1732468867000 = require('./src/migrations/1732468867000-add-resident-status-and-country-code').AddResidentStatusAndCountryCode1732468867000;

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  database: process.env.DB_NAME || 'paykey',
  entities: [path.join(__dirname, 'src/**/*.entity.{ts,js}')],
  migrations: [
    AddIsOnboardingCompletedToUser1732467840000,
    AddResidentStatusAndCountryCode1732468867000,
  ],
  synchronize: false,
  logging: true,
});

async function runMigrations() {
  try {
    console.log('🔄 Initializing database connection...');
    await AppDataSource.initialize();
    console.log('✅ Database connected successfully');
    
    console.log('🔄 Running TypeORM migrations...');
    const migrations = await AppDataSource.runMigrations();
    console.log('✅ Migrations completed successfully');
    
    if (migrations && migrations.length > 0) {
      console.log('\n📋 Applied migrations:');
      migrations.forEach(migration => {
        console.log(`✅ ${migration.name} (${new Date(migration.timestamp).toISOString()})`);
      });
    } else {
      console.log('ℹ️ No new migrations to apply');
    }
    
    // Verify migrations table
    const migrationCount = await AppDataSource.query('SELECT COUNT(*) as count FROM migrations');
    console.log(`\n📊 Total migrations in database: ${migrationCount[0].count}`);
    
    console.log('\n🎉 Migration setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    
    // Log additional details for debugging
    if (error.query) {
      console.error('📄 Query that failed:', error.query);
    }
    if (error.parameters) {
      console.error('🔧 Parameters:', error.parameters);
    }
    
    process.exit(1);
  } finally {
    await AppDataSource.destroy();
  }
}

runMigrations();
