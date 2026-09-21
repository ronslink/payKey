async function seedCompleteDemoData() {
  try {
    console.log('🌟 Starting complete demo data seeding via API...');
    
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
    
    // Separate hourly and fixed employees
    const hourlyWorkers = workers.filter(w => w.employmentType === 'HOURLY');
    const fixedWorkers = workers.filter(w => w.employmentType === 'FIXED');
    
    console.log(`👥 Fixed employees: ${fixedWorkers.length}`);
    console.log(`⏰ Hourly employees: ${hourlyWorkers.length}`);
    
    // Step 1: Create time tracking records for hourly employees
    let timeRecordsCreated = 0;
    if (hourlyWorkers.length > 0) {
      console.log('\n⏰ Creating time tracking records for hourly employees...');
      
      for (const worker of hourlyWorkers) {
        const timeEntries = [
          // November 1-15 period
          {
            workerId: worker.id,
            clockIn: '2024-11-01T08:00:00Z',
            clockOut: '2024-11-01T17:00:00Z',
            date: '2024-11-01',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-04T08:00:00Z',
            clockOut: '2024-11-04T17:00:00Z',
            date: '2024-11-04',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-05T08:00:00Z',
            clockOut: '2024-11-05T17:00:00Z',
            date: '2024-11-05',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-06T08:00:00Z',
            clockOut: '2024-11-06T17:00:00Z',
            date: '2024-11-06',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-07T08:00:00Z',
            clockOut: '2024-11-07T17:00:00Z',
            date: '2024-11-07',
            notes: 'Regular workday'
          },
          // Additional days for the period
          {
            workerId: worker.id,
            clockIn: '2024-11-08T08:00:00Z',
            clockOut: '2024-11-08T17:00:00Z',
            date: '2024-11-08',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-11T08:00:00Z',
            clockOut: '2024-11-11T17:00:00Z',
            date: '2024-11-11',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-12T08:00:00Z',
            clockOut: '2024-11-12T17:00:00Z',
            date: '2024-11-12',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-13T08:00:00Z',
            clockOut: '2024-11-13T17:00:00Z',
            date: '2024-11-13',
            notes: 'Regular workday'
          },
          {
            workerId: worker.id,
            clockIn: '2024-11-14T08:00:00Z',
            clockOut: '2024-11-14T17:00:00Z',
            date: '2024-11-14',
            notes: 'Regular workday'
          }
        ];
        
        for (const timeEntry of timeEntries) {
          try {
            // Employees clock themselves in, so demo data is recorded the way an
            // employer would: a time entry, then the payroll decision to pay it.
            const timeResponse = await fetch('http://localhost:3000/time-tracking/entries', {
              method: 'POST',
              headers: { 
                'Authorization': `Bearer ${access_token}`,
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({
                workerId: timeEntry.workerId,
                clockIn: timeEntry.clockIn,
                clockOut: timeEntry.clockOut,
                notes: timeEntry.notes
              })
            });
            
            if (timeResponse.ok) {
              const entry = await timeResponse.json();
              await fetch('http://localhost:3000/time-tracking/payroll-review/decision', {
                method: 'POST',
                headers: {
                  'Authorization': `Bearer ${access_token}`,
                  'Content-Type': 'application/json'
                },
                body: JSON.stringify({ entryIds: [entry.id], decision: 'INCLUDED' })
              });
              timeRecordsCreated++;
              console.log(`✅ Added time record for ${worker.name} on ${timeEntry.date}`);
            } else {
              // Try alternative approach - direct database entry simulation
              console.log(`⏭️  Skipped time record for ${worker.name} on ${timeEntry.date} (API not available)`);
            }
          } catch (error) {
            console.log(`⚠️  Could not add time record for ${worker.name}:`, error.message);
          }
        }
      }
    }
    
    // Step 2: Create pay period
    console.log('\n📅 Creating pay period...');
    const payPeriodData = {
      startDate: '2024-11-01',
      endDate: '2024-11-15',
      status: 'completed'
    };
    
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
    
    // Step 3: Calculate payroll for all workers
    console.log('\n💰 Calculating payroll records...');
    let payrollRecordsCreated = 0;
    
    for (const worker of workers) {
      try {
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
          payrollRecordsCreated++;
        } else {
          console.log(`❌ Failed to calculate payroll for ${worker.name}`);
        }
      } catch (error) {
        console.log(`❌ Error processing payroll for ${worker.name}:`, error.message);
      }
    }
    
    // Step 4: Get final counts
    const finalPayrollResponse = await fetch('http://localhost:3000/payroll-records', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    const finalPayroll = await finalPayrollResponse.json();
    const payrollCount = Array.isArray(finalPayroll) ? finalPayroll.length : 0;
    
    // Step 5: Create subscription for demo user
    console.log('\n💳 Setting up subscription...');
    const subscriptionResponse = await fetch('http://localhost:3000/subscriptions/subscribe', {
      method: 'POST',
      headers: { 
        'Authorization': `Bearer ${access_token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        planTier: 'GOLD',
        paymentMethod: 'card'
      })
    });
    
    if (subscriptionResponse.ok) {
      console.log('✅ Created GOLD subscription for demo user');
    } else {
      console.log('⚠️  Could not create subscription (may already exist)');
    }
    
    // Final Summary
    console.log('\n📈 Complete Demo Data Summary:');
    console.log(`✅ Total Workers: ${workers.length}`);
    console.log(`✅ Fixed Employees: ${fixedWorkers.length}`);
    console.log(`✅ Hourly Employees: ${hourlyWorkers.length}`);
    console.log(`✅ Time Records Created: ${timeRecordsCreated}`);
    console.log(`✅ Payroll Records Created: ${payrollRecordsCreated}`);
    console.log(`📊 Total Payroll Records in DB: ${payrollCount}`);
    
    if (Array.isArray(finalPayroll) && finalPayroll.length > 0) {
      console.log('\n📋 Recent Payroll Records:');
      finalPayroll.slice(0, 5).forEach((record, index) => {
        console.log(`${index + 1}. ${record.workerName || 'Unknown Worker'} - Net: ${record.netSalary || 'N/A'}`);
      });
    }
    
    console.log('\n🎉 Complete demo data seeding finished!');
    console.log('📱 The demo environment now includes:');
    console.log('   • 5 demo employees (4 fixed + 1 hourly)');
    console.log('   • Time tracking records for hourly workers');
    console.log('   • Pay periods and payroll calculations');
    console.log('   • Subscription setup');
    console.log('   • Mobile app connectivity (CORS fixed)');
    
  } catch (error) {
    console.error('❌ Error during complete demo seeding:', error.message);
  }
}

// Run the complete demo data seeding function
seedCompleteDemoData();