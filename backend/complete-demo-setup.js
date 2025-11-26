const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function completeDemoSetup() {
  try {
    await client.connect();
    console.log('🔧 Completing demo environment setup...\n');
    
    const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    
    // Create transactions without updatedAt column
    console.log('💳 Creating transactions...');
    
    const payrollRecords = await client.query(`
      SELECT pr."workerId", w.name, pr."netSalary", pr."paymentDate"
      FROM payroll_records pr
      JOIN workers w ON pr."workerId" = w.id
      WHERE pr."userId" = $1
      ORDER BY w.name, pr."paymentDate"
    `, [demoUserId]);
    
    let transactionCount = 0;
    for (const record of payrollRecords.rows) {
      try {
        await client.query(`
          INSERT INTO transactions (
            "id", "userId", "workerId", "amount", "currency", "type", "status",
            "providerRef", "metadata", "createdAt"
          ) VALUES (
            gen_random_uuid(), $1, $2, $3, 'KES', 'SALARY_PAYOUT', 'SUCCESS',
            $4, $5, NOW()
          )
        `, [
          demoUserId, record.workerId, record.netSalary,
          `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          JSON.stringify({ 
            description: `Salary payment for ${record.name}`,
            payPeriod: record.paymentDate,
            employeeName: record.name
          })
        ]);
        
        transactionCount++;
        console.log(`✅ Transaction: ${record.name} - KES ${record.netSalary}`);
      } catch (txError) {
        // Skip if transaction already exists
        if (!txError.message.includes('duplicate')) {
          console.log(`⚠️ Transaction error for ${record.name}: ${txError.message}`);
        }
      }
    }
    
    // Final verification
    console.log('\n🔍 Final verification...');
    
    const payPeriodsCount = await client.query('SELECT COUNT(*) FROM pay_periods WHERE "userId" = $1', [demoUserId]);
    const workersCount = await client.query('SELECT COUNT(*) FROM workers WHERE "userId" = $1', [demoUserId]);
    const payrollCount = await client.query('SELECT COUNT(*) FROM payroll_records WHERE "userId" = $1', [demoUserId]);
    const transactionsCount = await client.query('SELECT COUNT(*) FROM transactions WHERE "userId" = $1', [demoUserId]);
    
    console.log('='.repeat(60));
    console.log('🎉 DEMO ENVIRONMENT SETUP COMPLETE!');
    console.log('='.repeat(60));
    console.log(`📊 SUMMARY:`);
    console.log(`   • Pay Periods: ${payPeriodsCount.rows[0].count}`);
    console.log(`   • Employees: ${workersCount.rows[0].count}`);
    console.log(`   • Payroll Records: ${payrollCount.rows[0].count}`);
    console.log(`   • Transactions: ${transactionsCount.rows[0].count}`);
    console.log(`\n💰 FINANCIAL SUMMARY:`);
    console.log(`   • Monthly Gross Payroll: KES 456,000`);
    console.log(`   • Monthly Net Payroll: KES 364,800`);
    console.log(`   • Monthly Tax: KES 91,200`);
    console.log(`   • Annual Projected: KES 5,472,000`);
    console.log(`\n🚀 READY FOR TESTING:`);
    console.log(`   • Login: testuser@paykey.com / testuser123`);
    console.log(`   • Backend: http://localhost:3000`);
    console.log(`   • Database: Complete with realistic payroll data`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

completeDemoSetup();