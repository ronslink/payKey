const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  port: 5432,
});

async function verifyWorkers() {
  try {
    await client.connect();
    console.log('🔍 Verifying demo employees...\n');
    
    // Check demo user
    const userResult = await client.query('SELECT id, email, "firstName", "lastName" FROM users WHERE email = $1', ['testuser@paykey.com']);
    if (userResult.rows.length === 0) {
      console.log('❌ Demo user not found');
      return;
    }
    
    const demoUser = userResult.rows[0];
    console.log(`✅ Demo User: ${demoUser.firstName} ${demoUser.lastName} (${demoUser.email})`);
    console.log(`   ID: ${demoUser.id}\n`);
    
    // Check workers
    const workersResult = await client.query(`
      SELECT name, "jobTitle", "employmentType", "salaryGross", "housingAllowance", "transportAllowance", "paymentFrequency", "isActive"
      FROM workers 
      WHERE "userId" = $1 
      ORDER BY name
    `, [demoUser.id]);
    
    console.log(`📊 Demo Employees (${workersResult.rows.length} total):`);
    console.log('='.repeat(80));
    
    if (workersResult.rows.length === 0) {
      console.log('❌ No workers found for demo user');
      return;
    }
    
    let totalGross = 0;
    let totalHousing = 0;
    let totalTransport = 0;
    
    workersResult.rows.forEach((worker, index) => {
      const gross = parseFloat(worker.salaryGross || 0);
      const housing = parseFloat(worker.housingAllowance || 0);
      const transport = parseFloat(worker.transportAllowance || 0);
      const totalCompensation = gross + housing + transport;
      
      totalGross += gross;
      totalHousing += housing;
      totalTransport += transport;
      
      console.log(`${index + 1}. ${worker.name}`);
      console.log(`   Position: ${worker.jobTitle}`);
      console.log(`   Type: ${worker.employmentType} | Status: ${worker.isActive ? 'Active' : 'Inactive'}`);
      console.log(`   Salary: KES ${gross.toLocaleString()}`);
      if (housing > 0) console.log(`   Housing: KES ${housing.toLocaleString()}`);
      if (transport > 0) console.log(`   Transport: KES ${transport.toLocaleString()}`);
      console.log(`   Total Compensation: KES ${totalCompensation.toLocaleString()}`);
      console.log(`   Payment Frequency: ${worker.paymentFrequency}`);
      console.log('');
    });
    
    const grandTotal = totalGross + totalHousing + totalTransport;
    console.log('='.repeat(80));
    console.log(`📈 TOTALS:`);
    console.log(`   Base Salaries: KES ${totalGross.toLocaleString()}`);
    console.log(`   Housing Allowance: KES ${totalHousing.toLocaleString()}`);
    console.log(`   Transport Allowance: KES ${totalTransport.toLocaleString()}`);
    console.log(`   Grand Total: KES ${grandTotal.toLocaleString()}`);
    console.log(`   Average per Employee: KES ${(grandTotal / workersResult.rows.length).toLocaleString()}`);
    
  } catch (error) {
    console.error('❌ Verification failed:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Verification complete');
  }
}

verifyWorkers();
