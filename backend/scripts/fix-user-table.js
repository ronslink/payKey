const { Client } = require('pg');
const fs = require('fs');

async function fixUserTable() {
  const client = new Client({
    host: 'localhost',
    database: 'paykey',
    user: 'postgres',
    password: 'admin',
    port: 5432,
    // Add connection timeout
    connectionTimeoutMillis: 5000,
    query_timeout: 10000,
  });

  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database');

    // Check current columns
    console.log('📋 Checking current columns...');
    const columnsResult = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND table_schema = 'public'
    `);
    
    const existingColumns = columnsResult.rows.map(row => row.column_name);
    console.log('📊 Existing columns:', existingColumns);

    // List of required columns that might be missing
    const requiredColumns = [
      { name: 'payFrequency', definition: 'VARCHAR(20) DEFAULT \'MONTHLY\' NOT NULL' },
      { name: 'employeePaymentMethod', definition: 'VARCHAR(20) DEFAULT \'MPESA\' NOT NULL' },
      { name: 'mpesaNumber', definition: 'VARCHAR(20)' },
      { name: 'bankName', definition: 'VARCHAR(100)' },
      { name: 'bankAccount', definition: 'VARCHAR(50)' },
      { name: 'bankBranchCode', definition: 'VARCHAR(20)' },
    ];

    // Add missing columns
    for (const column of requiredColumns) {
      if (!existingColumns.includes(column.name)) {
        console.log(`➕ Adding column: ${column.name}`);
        try {
          await client.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ${column.name} ${column.definition}`);
          console.log(`✅ Successfully added column: ${column.name}`);
        } catch (error) {
          console.error(`❌ Failed to add column ${column.name}:`, error.message);
        }
      } else {
        console.log(`✅ Column already exists: ${column.name}`);
      }
    }

    // Update existing users with default values
    console.log('🔄 Updating existing users with default values...');
    const updateResult = await client.query(`
      UPDATE users 
      SET 
        payFrequency = COALESCE(payFrequency, 'MONTHLY'),
        employeePaymentMethod = COALESCE(employeePaymentMethod, 'MPESA')
      WHERE payFrequency IS NULL OR employeePaymentMethod IS NULL
    `);
    
    if (updateResult.rowCount > 0) {
      console.log(`✅ Updated ${updateResult.rowCount} users with default values`);
    }

    console.log('🎉 Database schema fix completed successfully!');
    
  } catch (error) {
    console.error('💥 Error fixing database schema:', error.message);
    if (error.code) {
      console.error('Error code:', error.code);
    }
  } finally {
    console.log('🔌 Closing database connection...');
    await client.end();
    console.log('✅ Database connection closed');
  }
}

// Run the fix
fixUserTable().then(() => {
  console.log('✅ Script completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Script failed:', error.message);
  process.exit(1);
});
