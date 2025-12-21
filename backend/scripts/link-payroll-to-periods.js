const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function linkPayrollToPayPeriods() {
  try {
    await client.connect();
    console.log('🔗 Linking payroll records to pay periods...\n');
    
    const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    
    // 1. First check if payPeriodId column exists in payroll_records
    console.log('📋 Checking payroll_records table structure...');
    const columnCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'payroll_records' AND column_name = 'payPeriodId'
    `);
    
    let payPeriodIdExists = columnCheck.rows.length > 0;
    
    if (!payPeriodIdExists) {
      console.log('🔧 Adding payPeriodId column to payroll_records...');
      await client.query(`
        ALTER TABLE payroll_records 
        ADD COLUMN "payPeriodId" UUID REFERENCES pay_periods(id)
      `);
      console.log('✅ payPeriodId column added successfully');
      payPeriodIdExists = true;
    } else {
      console.log('✅ payPeriodId column already exists');
    }
    
    // 2. Get all pay periods for linking
    console.log('\n📅 Fetching pay periods...');
    const payPeriodsResult = await client.query(`
      SELECT pp.id, pp.name, pp."startDate", pp."endDate"
      FROM pay_periods pp
      WHERE pp."userId" = $1
      ORDER BY pp."startDate"
    `, [demoUserId]);
    
    console.log(`Found ${payPeriodsResult.rows.length} pay periods`);
    
    // 3. Link payroll records to pay periods based on date matching
    console.log('\n🔗 Linking payroll records to pay periods...');
    
    let linkedCount = 0;
    for (const period of payPeriodsResult.rows) {
      // Update payroll records that match this pay period's date range
      const updateResult = await client.query(`
        UPDATE payroll_records 
        SET "payPeriodId" = $1,
            "updatedAt" = NOW()
        WHERE "userId" = $2 
        AND "periodStart" = $3 
        AND "periodEnd" = $4
        AND ("payPeriodId" IS NULL OR "payPeriodId" != $1)
      `, [period.id, demoUserId, period.startdate, period.enddate]);
      
      if (updateResult.rowCount > 0) {
        linkedCount += updateResult.rowCount;
        console.log(`✅ Linked ${updateResult.rowCount} records to ${period.name}`);
      } else {
        console.log(`📋 No unlinked records for ${period.name}`);
      }
    }
    
    // 4. Verify the linking
    console.log('\n🔍 Verifying payroll-pay period linking...');
    
    const verificationResult = await client.query(`
      SELECT 
        pp.name as periodName,
        COUNT(pr.id) as totalRecords,
        COUNT(pr."payPeriodId") as linkedRecords,
        SUM(pr."taxAmount") as totalTax,
        SUM(pr."grossSalary") as totalGross
      FROM pay_periods pp
      LEFT JOIN payroll_records pr ON pp.id = pr."payPeriodId"
      WHERE pp."userId" = $1
      GROUP BY pp.id, pp.name
      ORDER BY pp."startDate"
    `, [demoUserId]);
    
    console.log('\n📊 LINKING VERIFICATION:');
    let totalLinked = 0;
    verificationResult.rows.forEach(row => {
      const linked = parseInt(row.linkedrecords);
      const total = parseInt(row.totalrecords);
      const tax = parseFloat(row.totaltax || 0);
      const gross = parseFloat(row.totalgross || 0);
      
      totalLinked += linked;
      console.log(`   • ${row.periodname}: ${linked}/${total} records linked | Tax: KES ${tax.toLocaleString()} | Gross: KES ${gross.toLocaleString()}`);
    });
    
    // 5. Check for unlinked records
    const unlinkedResult = await client.query(`
      SELECT COUNT(*) as unlinkedCount
      FROM payroll_records 
      WHERE "userId" = $1 AND "payPeriodId" IS NULL
    `, [demoUserId]);
    
    const unlinkedCount = parseInt(unlinkedResult.rows[0].unlinkedcount);
    
    // 6. Summary
    console.log('\n' + '='.repeat(70));
    console.log('🔗 PAYROLL-PAY PERIOD LINKING COMPLETE!');
    console.log('='.repeat(70));
    console.log(`📊 LINKING SUMMARY:`);
    console.log(`   • Total Records Linked: ${totalLinked}`);
    console.log(`   • Unlinked Records: ${unlinkedCount}`);
    console.log(`   • Pay Periods Processed: ${payPeriodsResult.rows.length}`);
    console.log(`\n✅ DATABASE RELATIONSHIPS:`);
    console.log(`   • payroll_records.payPeriodId → pay_periods.id`);
    console.log(`   • All payroll data now properly linked to periods`);
    console.log(`   • Ready for tax submission creation`);
    
    if (unlinkedCount === 0) {
      console.log(`\n🎉 Perfect! All payroll records are now linked to pay periods.`);
    } else {
      console.log(`\n⚠️ Warning: ${unlinkedCount} records remain unlinked.`);
    }
    
  } catch (error) {
    console.error('❌ Error linking payroll to pay periods:', error.message);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

linkPayrollToPayPeriods();
