const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function checkTaxTables() {
  try {
    await client.connect();
    console.log('🔍 Examining tax-related tables...\n');
    
    // Check tax-payments table structure
    console.log('💳 Tax Payments Table:');
    const taxPaymentsColumns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'tax_payments' 
      ORDER BY ordinal_position
    `);
    
    taxPaymentsColumns.rows.forEach(col => {
      console.log(`   • ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Check tax-table structure
    console.log('\n📊 Tax Table Structure:');
    const taxTableColumns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'tax_table' 
      ORDER BY ordinal_position
    `);
    
    taxTableColumns.rows.forEach(col => {
      console.log(`   • ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Check existing data counts
    console.log('\n📈 Existing Tax Data:');
    
    const taxPaymentsCount = await client.query('SELECT COUNT(*) FROM tax_payments');
    console.log(`   • Tax Payments: ${taxPaymentsCount.rows[0].count}`);
    
    const taxTableCount = await client.query('SELECT COUNT(*) FROM tax_table');
    console.log(`   • Tax Table Entries: ${taxTableCount.rows[0].count}`);
    
    const taxSubmissionsCount = await client.query('SELECT COUNT(*) FROM tax_submissions');
    console.log(`   • Tax Submissions: ${taxSubmissionsCount.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkTaxTables();
