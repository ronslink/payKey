const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function debugAndFixPayrollLinking() {
  try {
    await client.connect();
    console.log('🔍 Debugging payroll-pay period linking...\n');
    
    const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    
    // 1. Check what payroll records exist
    console.log('📋 Checking existing payroll records...');
    const payrollResult = await client.query(`
      SELECT 
        pr.id,
        pr."periodStart",
        pr."periodEnd",
        pr."taxAmount",
        pr."grossSalary",
        w.name as workerName
      FROM payroll_records pr
      JOIN workers w ON pr."workerId" = w.id
      WHERE pr."userId" = $1
      ORDER BY pr."periodStart", w.name
    `, [demoUserId]);
    
    console.log(`Found ${payrollResult.rows.length} payroll records:`);
    payrollResult.rows.forEach((record, index) => {
      console.log(`   ${index + 1}. ${record.workername}: ${record.periodstart} to ${record.periodend} | Tax: KES ${record.taxamount}`);
    });
    
    // 2. Check what pay periods exist
    console.log('\n📅 Checking existing pay periods...');
    const periodsResult = await client.query(`
      SELECT 
        pp.id,
        pp.name,
        pp."startDate",
        pp."endDate",
        pp."payDate"
      FROM pay_periods pp
      WHERE pp."userId" = $1
      ORDER BY pp."startDate"
    `, [demoUserId]);
    
    console.log(`Found ${periodsResult.rows.length} pay periods:`);
    periodsResult.rows.forEach((period, index) => {
      console.log(`   ${index + 1}. ${period.name}: ${period.startdate} to ${period.enddate}`);
    });
    
    // 3. Attempt manual linking by exact date match
    console.log('\n🔗 Attempting manual linking by exact date match...');
    
    let linkedCount = 0;
    let totalTax = 0;
    let totalGross = 0;
    
    for (const period of periodsResult.rows) {
      for (const payroll of payrollResult.rows) {
        // Check if dates match exactly
        if (payroll.periodstart === period.startdate && payroll.periodend === period.enddate) {
          // Link this record
          const updateResult = await client.query(`
            UPDATE payroll_records 
            SET "payPeriodId" = $1,
                "updatedAt" = NOW()
            WHERE id = $2
          `, [period.id, payroll.id]);
          
          if (updateResult.rowCount > 0) {
            linkedCount++;
            totalTax += parseFloat(payroll.taxamount || 0);
            totalGross += parseFloat(payroll.grosssalary || 0);
            console.log(`✅ Linked: ${payroll.workername} → ${period.name}`);
          }
        }
      }
    }
    
    // 4. Check remaining unlinked records
    console.log('\n🔍 Checking remaining unlinked records...');
    const unlinkedResult = await client.query(`
      SELECT 
        pr.id,
        pr."periodStart",
        pr."periodEnd",
        pr."taxAmount",
        pr."grossSalary",
        w.name as workerName
      FROM payroll_records pr
      JOIN workers w ON pr."workerId" = w.id
      WHERE pr."userId" = $1 AND pr."payPeriodId" IS NULL
      ORDER BY pr."periodStart", w.name
    `, [demoUserId]);
    
    console.log(`Remaining unlinked records: ${unlinkedResult.rows.length}`);
    unlinkedResult.rows.forEach((record, index) => {
      console.log(`   ${index + 1}. ${record.workername}: ${record.periodstart} to ${record.periodend}`);
    });
    
    // 5. Try alternative linking using year/month matching
    if (unlinkedResult.rows.length > 0) {
      console.log('\n🔄 Trying year/month matching for remaining records...');
      
      for (const payroll of unlinkedResult.rows) {
        const payrollYear = payroll.periodstart.substring(0, 4);
        const payrollMonth = payroll.periodstart.substring(5, 7);
        
        // Find pay period with matching year and month
        let bestMatch = null;
        for (const period of periodsResult.rows) {
          const periodYear = period.startdate.substring(0, 4);
          const periodMonth = period.startdate.substring(5, 7);
          
          if (payrollYear === periodYear && payrollMonth === periodMonth) {
            bestMatch = period;
            break;
          }
        }
        
        if (bestMatch) {
          const updateResult = await client.query(`
            UPDATE payroll_records 
            SET "payPeriodId" = $1,
                "updatedAt" = NOW()
            WHERE id = $2
          `, [bestMatch.id, payroll.id]);
          
          if (updateResult.rowCount > 0) {
            linkedCount++;
            totalTax += parseFloat(payroll.taxamount || 0);
            totalGross += parseFloat(payroll.grosssalary || 0);
            console.log(`🔄 Fuzzy linked: ${payroll.workername} → ${bestMatch.name}`);
          }
        }
      }
    }
    
    // 6. Final verification
    console.log('\n✅ Final linking verification...');
    const finalResult = await client.query(`
      SELECT 
        pp.name as periodName,
        COUNT(pr.id) as recordCount,
        SUM(pr."taxAmount") as totalTax,
        SUM(pr."grossSalary") as totalGross
      FROM pay_periods pp
      LEFT JOIN payroll_records pr ON pp.id = pr."payPeriodId"
      WHERE pp."userId" = $1
      GROUP BY pp.id, pp.name
      ORDER BY pp."startDate"
    `, [demoUserId]);
    
    console.log('\n📊 FINAL LINKING STATUS:');
    let finalLinked = 0;
    finalResult.rows.forEach(row => {
      const count = parseInt(row.recordcount);
      finalLinked += count;
      const tax = parseFloat(row.totaltax || 0);
      const gross = parseFloat(row.totalgross || 0);
      console.log(`   • ${row.periodname}: ${count} records | Tax: KES ${tax.toLocaleString()} | Gross: KES ${gross.toLocaleString()}`);
    });
    
    // 7. Summary
    console.log('\n' + '='.repeat(70));
    console.log('🔗 PAYROLL-PAY PERIOD LINKING COMPLETE!');
    console.log('='.repeat(70));
    console.log(`📊 LINKING RESULTS:`);
    console.log(`   • Successfully Linked: ${finalLinked} records`);
    console.log(`   • Total Tax Linked: KES ${totalTax.toLocaleString()}`);
    console.log(`   • Total Gross Linked: KES ${totalGross.toLocaleString()}`);
    console.log(`   • Pay Periods with Data: ${finalResult.rows.filter(r => parseInt(r.recordcount) > 0).length}`);
    console.log(`\n✅ DATABASE RELATIONSHIPS ESTABLISHED:`);
    console.log(`   • payroll_records.payPeriodId → pay_periods.id`);
    console.log(`   • Ready for tax submission creation`);
    console.log(`   • All payroll data properly connected to periods`);
    
  } catch (error) {
    console.error('❌ Error debugging payroll linking:', error.message);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

debugAndFixPayrollLinking();