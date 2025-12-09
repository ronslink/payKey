const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5435,
});

async function clearPayrollData() {
  try {
    await client.connect();
    console.log('🧹 Clearing payroll data...\n');
    
    // Delete all payroll records first (to maintain referential integrity)
    const payrollRecordsResult = await client.query('DELETE FROM payroll_records');
    console.log(`✅ Deleted ${payrollRecordsResult.rowCount} payroll records`);
    
    // Delete all pay periods
    const payPeriodsResult = await client.query('DELETE FROM pay_periods');
    console.log(`✅ Deleted ${payPeriodsResult.rowCount} pay periods`);
    
    // Verification
    const remainingPayrollRecords = await client.query('SELECT COUNT(*) as count FROM payroll_records');
    const remainingPayPeriods = await client.query('SELECT COUNT(*) as count FROM pay_periods');
    
    console.log('\n📊 Verification:');
    console.log(`   • Remaining payroll records: ${remainingPayrollRecords.rows[0].count}`);
    console.log(`   • Remaining pay periods: ${remainingPayPeriods.rows[0].count}`);
    
    console.log('\n🎉 Payroll data cleared successfully!');
    console.log('💡 You can now test the "Initialize Year" functionality in the Flutter app.');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

clearPayrollData();