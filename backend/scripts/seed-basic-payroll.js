const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function seedPayrollDemoData() {
  try {
    await client.connect();
    console.log('🌱 Starting comprehensive payroll demo data seeding...\n');
    
    const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    
    // 1. Create Pay Periods
    console.log('📅 Creating pay periods...');
    
    const payPeriodQueries = [
      // January 2025 - CLOSED
      `INSERT INTO pay_periods ("id", "userId", "title", "periodStart", "periodEnd", "status", "isActive", "processedAt", "createdAt", "updatedAt")
       VALUES (gen_random_uuid(), $1, 'January 2025', '2025-01-01', '2025-01-31', 'CLOSED', false, '2025-02-01 00:00:00', NOW(), NOW())
       ON CONFLICT (title, "userId") DO NOTHING;`,
       
      // February 2025 - CLOSED  
      `INSERT INTO pay_periods ("id", "userId", "title", "periodStart", "periodEnd", "status", "isActive", "processedAt", "createdAt", "updatedAt")
       VALUES (gen_random_uuid(), $1, 'February 2025', '2025-02-01', '2025-02-28', 'CLOSED', false, '2025-03-01 00:00:00', NOW(), NOW())
       ON CONFLICT (title, "userId") DO NOTHING;`,
       
      // March 2025 - PROCESSING
      `INSERT INTO pay_periods ("id", "userId", "title", "periodStart", "periodEnd", "status", "isActive", "createdAt", "updatedAt")
       VALUES (gen_random_uuid(), $1, 'March 2025', '2025-03-01', '2025-03-31', 'PROCESSING', true, NOW(), NOW())
       ON CONFLICT (title, "userId") DO NOTHING;`
    ];
    
    for (const query of payPeriodQueries) {
      await client.query(query, [demoUserId]);
      console.log('✅ Pay period created');
    }
    
    // 2. Get workers for payroll records
    console.log('\n👥 Fetching workers...');
    const workersResult = await client.query(`
      SELECT id, name, "salaryGross", "housingAllowance", "transportAllowance", "paymentMethod"
      FROM workers 
      WHERE "userId" = $1
      ORDER BY name
    `, [demoUserId]);
    
    console.log(`Found ${workersResult.rows.length} workers`);
    
    // 3. Get pay periods for payroll records
    const payPeriodsResult = await client.query(`
      SELECT id, title, "periodStart", "periodEnd", "processedAt"
      FROM pay_periods 
      WHERE "userId" = $1 AND status = 'CLOSED'
      ORDER BY "periodStart"
    `, [demoUserId]);
    
    console.log(`Found ${payPeriodsResult.rows.length} closed pay periods`);
    
    // 4. Create Payroll Records
    console.log('\n💰 Creating payroll records...');
    
    let payrollCount = 0;
    for (const period of payPeriodsResult.rows) {
      for (const worker of workersResult.rows) {
        const grossSalary = parseFloat(worker.salaryGross);
        const housingAllowance = parseFloat(worker.housingAllowance || 0);
        const transportAllowance = parseFloat(worker.transportAllowance || 0);
        const totalGross = grossSalary + housingAllowance + transportAllowance;
        
        // Simple tax calculation (20% of gross)
        const taxAmount = totalGross * 0.20;
        const netSalary = totalGross - taxAmount;
        
        // Check if payroll record already exists
        const existingPayroll = await client.query(`
          SELECT id FROM payroll_records 
          WHERE "workerId" = $1 AND "periodStart" = $2 AND "periodEnd" = $3
        `, [worker.id, period.periodStart, period.periodEnd]);
        
        if (existingPayroll.rows.length === 0) {
          await client.query(`
            INSERT INTO payroll_records (
              "id", "userId", "workerId", "periodStart", "periodEnd", "grossSalary", 
              "bonuses", "otherEarnings", "otherDeductions", "netSalary", "taxAmount",
              "status", "paymentStatus", "paymentMethod", "paymentDate", "finalizedAt",
              "createdAt", "updatedAt"
            ) VALUES (
              gen_random_uuid(), $1, $2, $3, $4, $5, 0, 0, 0, $6, $7,
              'PAID', 'PAID', $8, $9, $9, NOW(), NOW()
            )
          `, [
            demoUserId, worker.id, period.periodStart, period.periodEnd, 
            totalGross, netSalary, taxAmount, worker.paymentMethod, period.processedAt
          ]);
          
          payrollCount++;
          console.log(`✅ Payroll: ${worker.name} - ${period.title} (KES ${netSalary})`);
        }
      }
    }
    
    // 5. Create Transaction Records
    console.log('\n💳 Creating transactions...');
    
    const payrollRecords = await client.query(`
      SELECT pr.id, pr."workerId", w.name, pr."netSalary", pr."paymentDate"
      FROM payroll_records pr
      JOIN workers w ON pr."workerId" = w.id
      WHERE pr."userId" = $1
    `, [demoUserId]);
    
    let transactionCount = 0;
    for (const record of payrollRecords.rows) {
      // Check if transaction already exists
      const existingTransaction = await client.query(`
        SELECT id FROM transactions 
        WHERE "workerId" = $1 AND amount = $2 AND type = 'SALARY_PAYOUT'
      `, [record.workerid, record.netsalary]);
      
      if (existingTransaction.rows.length === 0) {
        await client.query(`
          INSERT INTO transactions (
            "id", "userId", "workerId", "amount", "currency", "type", "status",
            "providerRef", "metadata", "createdAt", "updatedAt"
          ) VALUES (
            gen_random_uuid(), $1, $2, $3, 'KES', 'SALARY_PAYOUT', 'SUCCESS',
            $4, $5, NOW(), NOW()
          )
        `, [
          demoUserId, 
          record.workerid, 
          record.netsalary,
          `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          JSON.stringify({
            payPeriod: record.paymentdate,
            description: `Salary payment for ${record.name}`
          })
        ]);
        
        transactionCount++;
        console.log(`✅ Transaction: ${record.name} - KES ${record.netsalary}`);
      }
    }
    
    // 6. Summary
    console.log('\n🎉 Demo data seeding completed!');
    console.log(`📊 Summary:`);
    console.log(`   • Pay Periods: ${payPeriodsResult.rows.length} (plus March 2025)`);
    console.log(`   • Workers: ${workersResult.rows.length}`);
    console.log(`   • Payroll Records Created: ${payrollCount}`);
    console.log(`   • Transactions Created: ${transactionCount}`);
    console.log(`\n💡 The demo environment now has complete payroll data!`);
    
  } catch (error) {
    console.error('❌ Error seeding demo data:', error.message);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

seedPayrollDemoData();
