import fetch from 'node-fetch';

async function seedDemoData() {
  try {
    console.log('🌱 Starting demo data seeding via API...');
    
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
    
    // First, check existing workers
    const workersResponse = await fetch('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    const existingWorkers = await workersResponse.json();
    console.log(`📊 Current workers count: ${Array.isArray(existingWorkers) ? existingWorkers.length : 0}`);
    
    // Demo workers data based on the SQL scripts
    const demoWorkers = [
      {
        name: 'Jane Doe',
        phoneNumber: '+254700123456',
        salaryGross: 15000.00,
        startDate: '2024-01-15',
        employmentType: 'FIXED',
        jobTitle: 'Accountant',
        hourlyRate: 865.38,
        housingAllowance: 0,
        transportAllowance: 0,
        mpesaNumber: '+254700123456'
      },
      {
        name: 'Kamau Wanjiku',
        phoneNumber: '+254700234567',
        salaryGross: 120000.00,
        startDate: '2024-02-01',
        employmentType: 'FIXED',
        jobTitle: 'Manager',
        hourlyRate: 6923.08,
        housingAllowance: 15000,
        transportAllowance: 8000,
        mpesaNumber: '+254700234567'
      },
      {
        name: 'Ochieng Achieng',
        phoneNumber: '+254700345678',
        salaryGross: 120000.00,
        startDate: '2024-03-01',
        employmentType: 'FIXED',
        jobTitle: 'Developer',
        hourlyRate: 6923.08,
        housingAllowance: 12000,
        transportAllowance: 5000,
        mpesaNumber: '+254700345678'
      },
      {
        name: 'Kiprotich Ngeny',
        phoneNumber: '+254700456789',
        salaryGross: 10000.00,
        startDate: '2024-04-01',
        employmentType: 'HOURLY',
        jobTitle: 'Contractor',
        hourlyRate: 200.00,
        housingAllowance: 0,
        transportAllowance: 0,
        mpesaNumber: '+254700456789'
      },
      {
        name: 'Mwangi Kamau',
        phoneNumber: '+254700567890',
        salaryGross: 120000.00,
        startDate: '2024-05-01',
        employmentType: 'FIXED',
        jobTitle: 'Supervisor',
        hourlyRate: 6923.08,
        housingAllowance: 10000,
        transportAllowance: 6000,
        mpesaNumber: '+254700567890'
      }
    ];
    
    let addedCount = 0;
    let skippedCount = 0;
    
    // Add workers that don't exist
    for (const workerData of demoWorkers) {
      // Check if worker already exists
      const existingWorker = Array.isArray(existingWorkers) ? 
        existingWorkers.find(w => w.name === workerData.name) : null;
      
      if (existingWorker) {
        console.log(`⏭️  Worker already exists: ${workerData.name}`);
        skippedCount++;
        continue;
      }
      
      try {
        const addWorkerResponse = await fetch('http://localhost:3000/workers', {
          method: 'POST',
          headers: { 
            'Authorization': `Bearer ${access_token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(workerData)
        });
        
        if (addWorkerResponse.ok) {
          const newWorker = await addWorkerResponse.json();
          console.log(`✅ Added worker: ${workerData.name} (${workerData.employmentType})`);
          addedCount++;
        } else {
          const error = await addWorkerResponse.text();
          console.log(`❌ Failed to add worker ${workerData.name}:`, error);
        }
      } catch (error) {
        console.log(`❌ Error adding worker ${workerData.name}:`, error.message);
      }
    }
    
    console.log('\n📈 Seeding Summary:');
    console.log(`✅ Added: ${addedCount} workers`);
    console.log(`⏭️  Skipped: ${skippedCount} workers (already exist)`);
    
    // Final verification
    const finalWorkersResponse = await fetch('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    const finalWorkers = await finalWorkersResponse.json();
    console.log(`📊 Total workers after seeding: ${Array.isArray(finalWorkers) ? finalWorkers.length : 0}`);
    
    if (Array.isArray(finalWorkers) && finalWorkers.length > 0) {
      console.log('\n👥 Demo Workers:');
      finalWorkers.forEach((worker, index) => {
        console.log(`${index + 1}. ${worker.name} - ${worker.jobTitle} (${worker.employmentType})`);
      });
    }
    
    console.log('\n🎉 Demo data seeding completed!');
    
  } catch (error) {
    console.error('❌ Error during seeding:', error.message);
  }
}

// Run the seeding function
seedDemoData();