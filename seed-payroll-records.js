async function seedPayrollData() {
  try {
    console.log('🏦 Starting payroll data seeding via API...');
    
    // Login to get token
    const loginResponse = await fetch('http://localhost:3000/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        email: 'testuser@paykey.com', 
        password: 'testuser123' 
      })
    });
    
    if (!loginResponse.ok) {
      console.log('❌ Login failed:', loginResponse.status, loginResponse.statusText);
      return;
    }
    
    const { access_token } = await loginResponse.json();
    console.log('✅ Login successful');
    
    // First, get workers to get their IDs
    const workersResponse = await fetch('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    const workers = await workersResponse.json();
    console.log(`📊 Found ${workers.length} workers`);
    
    if (!Array.isArray(workers) || workers.length === 0) {
      console.log('❌ No workers found. Please seed workers first.');
      return;
    }
    
    // Create pay period first
    const payPeriodData = {
      startDate: '2024-11-01',
      endDate: '2024-11-15',
      status: 'completed'
    };
    
    console.log('📅 Creating pay period...');
    const payPeriodResponse = await fetch('http://localhost:3000/pay-periods', {
      method: 'POST',
      headers: { 
        'Authorization': `Bearer ${access_token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payPeriodData)
    });
    
    let payPeriod;
    if (payPeriodResponse.ok) {
      payPeriod = await payPeriodResponse.json();
      console.log(`✅ Created pay period: ${payPeriod.id}`);
    } else {
      // Try to get existing pay periods
      const existingPeriodsResponse = await fetch('http://localhost:3000/pay-periods', {
        headers: { 'Authorization': `Bearer ${access_token}` }
      });
      const existingPeriods = await existingPeriodsResponse.json();
      
      if (Array.isArray(existingPeriods) && existingPeriods.length > 0) {
        payPeriod = existingPeriods[0];
        console.log(`📋 Using existing pay period: ${payPeriod.id}`);
      } else {
        console.log('❌ Could not create or find pay period');
        return;
      }
    }
    
    // Calculate payroll for each worker
    console.log('💰 Calculating payroll records...');
    let createdRecords = 0;
    
    for (const worker of workers) {
      try {
        // Calculate payroll for this worker
        const payrollData = {
          workerId: worker.id,
          payPeriodId: payPeriod.id
        };
        
        const payrollResponse = await fetch('http://localhost:3000/payroll/calculate', {
          method: 'POST',
          headers: { 
            'Authorization': `Bearer ${access_token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(payrollData)
        });
        
        if (payrollResponse.ok) {
          const payroll = await payrollResponse.json();
          console.log(`✅ Calculated payroll for ${worker.name}: ${payroll.netSalary || 'N/A'}`);
          createdRecords++;
        } else {
          console.log(`❌ Failed to calculate payroll for ${worker.name}`);
        }
      } catch (error) {
        console.log(`❌ Error processing payroll for ${worker.name}:`, error.message);
      }
    }
    
    // Get final payroll records count
    const finalPayrollResponse = await fetch('http://localhost:3000/payroll-records', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    const finalPayroll = await finalPayrollResponse.json();
    const recordCount = Array.isArray(finalPayroll) ? finalPayroll.length : 0;
    
    console.log('\n📈 Payroll Seeding Summary:');
    console.log(`✅ Workers processed: ${workers.length}`);
    console.log(`✅ Payroll calculations created: ${createdRecords}`);
    console.log(`📊 Total payroll records: ${recordCount}`);
    
    if (Array.isArray(finalPayroll) && finalPayroll.length > 0) {
      console.log('\n📋 Recent Payroll Records:');
      finalPayroll.slice(0, 5).forEach((record, index) => {
        console.log(`${index + 1}. ${record.workerName || 'Unknown'} - ${record.netSalary || 'N/A'}`);
      });
    }
    
    console.log('\n🎉 Payroll data seeding completed!');
    
  } catch (error) {
    console.error('❌ Error during payroll seeding:', error.message);
  }
}

// Run the payroll seeding function
seedPayrollData();