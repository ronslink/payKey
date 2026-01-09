const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  port: 5432,
});

async function checkTableStructure() {
  try {
    await client.connect();
    console.log('🔍 Checking table structures...\n');
    
    // Check pay_periods table structure
    console.log('📅 Pay Periods Table Structure:');
    const payPeriodsColumns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'pay_periods' 
      ORDER BY ordinal_position
    `);
    
    payPeriodsColumns.rows.forEach(col => {
      console.log(`   • ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Check if there are any existing records
    console.log('\n📊 Existing Data:');
    
    const periodsCount = await client.query('SELECT COUNT(*) FROM pay_periods');
    console.log(`   • Pay Periods: ${periodsCount.rows[0].count}`);
    
    const workersCount = await client.query('SELECT COUNT(*) FROM workers');
    console.log(`   • Workers: ${workersCount.rows[0].count}`);
    
    const payrollCount = await client.query('SELECT COUNT(*) FROM payroll_records');
    console.log(`   • Payroll Records: ${payrollCount.rows[0].count}`);
    
    const transactionsCount = await client.query('SELECT COUNT(*) FROM transactions');
    console.log(`   • Transactions: ${transactionsCount.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkTableStructure();
