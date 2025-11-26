const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function examineTaxTables() {
  try {
    await client.connect();
    console.log('🔍 Examining tax table structures...\n');
    
    // Check tax_tables structure
    console.log('📊 Tax Tables Structure:');
    const taxTablesColumns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'tax_tables' 
      ORDER BY ordinal_position
    `);
    
    taxTablesColumns.rows.forEach(col => {
      console.log(`   • ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Check tax_submissions structure
    console.log('\n📋 Tax Submissions Structure:');
    const taxSubmissionsColumns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'tax_submissions' 
      ORDER BY ordinal_position
    `);
    
    taxSubmissionsColumns.rows.forEach(col => {
      console.log(`   • ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Check existing data
    console.log('\n📈 Current Tax Data:');
    
    const taxTablesCount = await client.query('SELECT COUNT(*) FROM tax_tables');
    console.log(`   • Tax Tables Entries: ${taxTablesCount.rows[0].count}`);
    
    const taxSubmissionsCount = await client.query('SELECT COUNT(*) FROM tax_submissions');
    console.log(`   • Tax Submissions: ${taxSubmissionsCount.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

examineTaxTables();