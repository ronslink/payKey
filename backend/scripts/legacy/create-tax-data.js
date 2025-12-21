const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function createComprehensiveTaxData() {
  try {
    await client.connect();
    console.log('🧾 Creating comprehensive tax data for demo environment...\n');
    
    const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    
    // 1. Get pay periods and their tax calculations
    console.log('📅 Fetching pay periods for tax submissions...');
    const payPeriodsResult = await client.query(`
      SELECT pp.id, pp.name, pp."payDate", 
             SUM(pr."taxAmount") as totalTax
      FROM pay_periods pp
      LEFT JOIN payroll_records pr ON pp.id = pr."payPeriodId"
      WHERE pp."userId" = $1 AND pp.status = 'COMPLETED'
      GROUP BY pp.id, pp.name, pp."payDate"
      ORDER BY pp."payDate"
    `, [demoUserId]);
    
    console.log(`Found ${payPeriodsResult.rows.length} completed pay periods for tax filings`);
    
    // 2. Create Tax Submissions for each completed period
    console.log('\n📋 Creating tax submissions...');
    
    let submissionCount = 0;
    for (const period of payPeriodsResult.rows) {
      const totalTax = parseFloat(period.totaltax || 0);
      
      // Calculate realistic Kenyan tax breakdown (approximate)
      const totalPaye = totalTax * 0.85; // 85% PAYE tax
      const totalNssf = 12000; // Standard NSSF contribution
      const totalNhif = totalPaye * 0.025; // 2.5% NHIF
      const totalHousingLevy = totalPaye * 0.015; // 1.5% Housing Levy
      
      // Check if submission already exists
      const existingSubmission = await client.query(`
        SELECT id FROM tax_submissions 
        WHERE "userId" = $1 AND "payPeriodId" = $2
      `, [demoUserId, period.id]);
      
      if (existingSubmission.rows.length === 0) {
        await client.query(`
          INSERT INTO tax_submissions (
            "id", "userId", "payPeriodId", "totalPaye", "totalNssf", "totalNhif", 
            "totalHousingLevy", "status", "filingDate", "createdAt", "updatedAt"
          ) VALUES (
            gen_random_uuid(), $1, $2, $3, $4, $5, $6, 'FILED', $7, NOW(), NOW()
          )
        `, [
          demoUserId, 
          period.id, 
          totalPaye, 
          totalNssf, 
          totalNhif, 
          totalHousingLevy, 
          period.paydate
        ]);
        
        submissionCount++;
        console.log(`✅ Tax submission: ${period.name} - KES ${(totalPaye + totalNssf + totalNhif + totalHousingLevy).toLocaleString()}`);
      }
    }
    
    // 3. Check and update tax table if needed
    console.log('\n📊 Checking tax configuration...');
    const currentTaxTable = await client.query(`
      SELECT * FROM tax_tables 
      WHERE year = 2025 AND "isActive" = true
    `);
    
    if (currentTaxTable.rows.length === 0) {
      console.log('📝 Creating 2025 tax configuration...');
      
      await client.query(`
        INSERT INTO tax_tables (
          "id", "year", "effectiveDate", "nssfConfig", "nhifConfig", 
          "housingLevyRate", "payeBands", "personalRelief", "isActive",
          "createdAt", "updatedAt"
        ) VALUES (
          gen_random_uuid(), 2025, '2025-01-01', 
          $1, $2, $3, $4, $5, true, NOW(), NOW()
        )
      `, [
        JSON.stringify({
          employeeRate: 0.06,
          employerRate: 0.12,
          maxContribution: 2160
        }),
        JSON.stringify({
          minimum: 6000,
          maximum: 40000,
          rate: 0.025
        }),
        0.015, // Housing Levy 1.5%
        JSON.stringify([
          { min: 0, max: 288000, rate: 0.10, relief: 2400 },
          { min: 288000, max: 388000, rate: 0.25, relief: 2400 },
          { min: 388000, max: 600000, rate: 0.30, relief: 2400 },
          { min: 600000, max: 99999999, rate: 0.325, relief: 2400 }
        ]),
        2400 // Monthly personal relief
      ]);
      
      console.log('✅ Tax configuration created for 2025');
    } else {
      console.log('✅ Tax configuration already exists for 2025');
    }
    
    // 4. Calculate total tax summary
    console.log('\n💰 Calculating tax summary...');
    
    const taxSummary = await client.query(`
      SELECT 
        COUNT(*) as submissions,
        COALESCE(SUM("totalPaye"), 0) as totalPaye,
        COALESCE(SUM("totalNssf"), 0) as totalNssf,
        COALESCE(SUM("totalNhif"), 0) as totalNhif,
        COALESCE(SUM("totalHousingLevy"), 0) as totalHousingLevy
      FROM tax_submissions 
      WHERE "userId" = $1
    `, [demoUserId]);
    
    const summary = taxSummary.rows[0];
    const grandTotal = parseFloat(summary.totalpaye) + parseFloat(summary.totalnssf) + 
                      parseFloat(summary.totalnhif) + parseFloat(summary.totalhousinglevy);
    
    // 5. Final verification
    console.log('\n🔍 Final tax data verification...');
    
    const verifyPaye = await client.query(`
      SELECT SUM("taxAmount") as calculatedTax 
      FROM payroll_records 
      WHERE "userId" = $1
    `, [demoUserId]);
    
    const calculatedTax = parseFloat(verifyPaye.rows[0].calculatedtax || 0);
    
    console.log('=' .repeat(70));
    console.log('🧾 COMPREHENSIVE TAX DATA CREATION COMPLETE!');
    console.log('=' .repeat(70));
    console.log(`📊 TAX SUBMISSIONS: ${summary.submissions}`);
    console.log(`💰 TAX BREAKDOWN:`);
    console.log(`   • PAYE Tax: KES ${parseFloat(summary.totalpaye).toLocaleString()}`);
    console.log(`   • NSSF: KES ${parseFloat(summary.totalnssf).toLocaleString()}`);
    console.log(`   • NHIF: KES ${parseFloat(summary.totalnhif).toLocaleString()}`);
    console.log(`   • Housing Levy: KES ${parseFloat(summary.totalhousinglevy).toLocaleString()}`);
    console.log(`   • TOTAL TAX: KES ${grandTotal.toLocaleString()}`);
    console.log(`\n📈 COMPARISON:`);
    console.log(`   • Payroll Tax Calc: KES ${calculatedTax.toLocaleString()}`);
    console.log(`   • Tax Submission: KES ${grandTotal.toLocaleString()}`);
    console.log(`   • Difference: KES ${(grandTotal - calculatedTax).toLocaleString()}`);
    console.log(`\n🎯 DEMO TAX SYSTEM:`);
    console.log(`   ✅ Tax tables configured for Kenya 2025`);
    console.log(`   ✅ Tax submissions for all completed pay periods`);
    console.log(`   ✅ Realistic tax breakdown (PAYE, NSSF, NHIF, Housing Levy)`);
    console.log(`   ✅ Tax filings status: FILED`);
    console.log(`   ✅ All tax data ready for compliance testing`);
    
  } catch (error) {
    console.error('❌ Error creating tax data:', error.message);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

createComprehensiveTaxData();