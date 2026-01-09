const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  port: 5432,
});

async function checkPayrollTable() {
  try {
    await client.connect();
    console.log('💰 Checking payroll_records table structure...\n');
    
    const payrollColumns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'payroll_records' 
      ORDER BY ordinal_position
    `);
    
    payrollColumns.rows.forEach(col => {
      console.log(`   • ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkPayrollTable();
