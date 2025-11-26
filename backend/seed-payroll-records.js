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
      // January 2025 - COMPLETED
      `INSERT INTO pay_periods ("id", "userId", "name", "startDate", "endDate", "payDate", "frequency", "status", "totalGrossAmount", "totalNetAmount", "totalTaxAmount", "totalWorkers", "processedWorkers", "createdAt", "updatedAt")
       VALUES (gen_random_uuid(), $1, 'January 2025', '2025-01-01', '2025-01-31', '2025-02-01', 'MONTHLY', 'COMPLETED', 912000, 729600, 182400, 6, 6, NOW(), NOW())
       ON CONFLICT DO NOTHING;`,
       
      // February 2025 - COMPLETED  
      `INSERT INTO pay_periods ("id", "userId", "name", "startDate", "endDate", "payDate", "frequency", "status", "totalGrossAmount", "totalNetAmount", "totalTaxAmount", "totalWorkers", "processedWorkers", "createdAt", "updatedAt")
       VALUES (gen_random_uuid(), $1, 'February 2025', '2025-02-01', '2025-02-28', '2025-03-01', 'MONTHLY', 'COMPLETED', 912000, 729600, 182400, 6, 6, NOW(), NOW())
       ON CONFLICT DO NOTHING;`,
       
      // March 2025 - PROCESSING
      `INSERT INTO pay_periods ("id", "userId", "name", "startDate", "endDate", "frequency", "status", "totalGrossAmount", "totalNetAmount", "totalTaxAmount", "totalWorkers", "processedWorkers", "createdAt", "updatedAt")
       VALUES (gen_random_uuid(), $1, 'March 2025', '2025-03-01', '2025-03-31', 'MONTHLY', 'PROCESSING', 912000, 729600, 182400, 6, 0, NOW(), NOW())
       ON CONFLICT DO NOTHING;`
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
      SELECT id, name, "startDate", "endDate", "payDate", "status"
      FROM pay_periods 
      WHERE "userId" = $1 AND status = 'COMPLETED'
      ORDER BY "startDate"
    `, [demoUserId]);
    
    console.log(`Found ${payPeriodsResult.rows.length} completed pay periods`);
    
    // 4. Create Payroll Records for completed periods
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
        `, [worker.id, period.startdate, period.enddate]);
        
        if (existingPayroll.rows.length === 0) {
          await client.query(`
            INSERT INTO payroll_records (
              "id", "userId", "workerId", "periodStart", "periodEnd", "grossSalary", 
              "netSalary", "taxAmount", "paymentStatus", "paymentMethod", "paymentDate",
              "taxBreakdown", "deductions", "createdAt", "updatedAt"
            ) VALUES (
              gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7,
              'PAID', $8, $9, $10, $11, NOW(), NOW()
            )
          `, [
            demoUserId, worker.id, period.startdate, period.enddate, 
            totalGross, netSalary, taxAmount, 
            worker.paymentMethod, period.paydate,
            JSON.stringify({
              incomeTax: taxAmount,
              nssf: 0,
              nhif: 0,
              totalTax: taxAmount
            }),
            JSON.stringify({
              nssf: 0,
              nhif: 0,
              other: 0
            })
          ]);
          
          payrollCount++;
          console.log(`✅ Payroll: ${worker.name} - ${period.name} (KES ${netSalary})`);
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
            description: `Salary payment for ${record.name}`,
            employeeName: record.name
          })
        ]);
        
        transactionCount++;
        console.log(`✅ Transaction: ${record.name} - KES ${record.netsalary}`);
      }
    }
    
    // 6. Summary
    console.log('\n🎉 Demo data seeding completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   • Pay Periods: ${payPeriodsResult.rows.length} (plus March 2025)`);
    console.log(`   • Workers: ${workersResult.rows.length}`);
    console.log(`   • Payroll Records Created: ${payrollCount}`);
    console.log(`   • Transactions Created: ${transactionCount}`);
    console.log(`\n💡 The demo environment now has complete payroll data!`);
    console.log(`🔍 Total Monthly Payroll: KES 456,000 (gross) | KES 364,800 (net) | KES 91,200 (tax)`);
    
  } catch (error) {
    console.error('❌ Error seeding demo data:', error.message);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

seedPayrollDemoData();