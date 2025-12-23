import { createConnection } from 'typeorm';
import { config } from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

// Load environment variables
config();

async function createTaxConfigsTable() {
  try {
    console.log('Connecting to database...');

    // Create connection
    const connection = await createConnection({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT || '5432', 10),
      username: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      entities: [],
      synchronize: false,
      logging: true,
    });

    console.log('Connected successfully!');

    // Read SQL file
    const sqlFilePath = path.join(__dirname, 'create_tax_configs.sql');
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

    console.log('Executing SQL...');

    // Split SQL into individual statements and execute
    const statements = sqlContent
      .split(';')
      .map((stmt) => stmt.trim())
      .filter((stmt) => stmt.length > 0);

    for (const statement of statements) {
      if (statement.length > 0) {
        console.log(`Executing: ${statement.substring(0, 100)}...`);
        await connection.query(statement);
      }
    }

    console.log('Tax configs table created successfully!');

    // Verify table exists
    const result = await connection.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'tax_configs'
    `);

    if (result.length > 0) {
      console.log('✅ tax_configs table confirmed to exist in database');
    } else {
      console.log('❌ tax_configs table not found');
    }

    await connection.close();
    console.log('Database connection closed.');
  } catch (error) {
    console.error('Error creating tax_configs table:', error);
    process.exit(1);
  }
}

createTaxConfigsTable();
