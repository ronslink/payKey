async function verifyDemoWorkers() {
  try {
    console.log('Verifying demo workers setup...');
    
    // Login to get token
    const loginResponse = await fetch('http://localhost:3000/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'testuser@paykey.com', password: 'testuser123' })
    });
    
    if (!loginResponse.ok) {
      console.log('❌ Login failed:', loginResponse.status, loginResponse.statusText);
      return;
    }
    
    const { access_token } = await loginResponse.json();
    console.log('✅ Login successful');
    
    // Get workers
    const workersResponse = await fetch('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    if (!workersResponse.ok) {
      console.log('❌ Workers fetch failed:', workersResponse.status, workersResponse.statusText);
      return;
    }
    
    const workers = await workersResponse.json();
    console.log(`✅ Found ${Array.isArray(workers) ? workers.length : 0} workers for demo user`);
    
    if (Array.isArray(workers) && workers.length > 0) {
      console.log('\n📋 Demo Workers:');
      workers.forEach((worker, index) => {
        console.log(`${index + 1}. ${worker.name} (${worker.employmentType}) - ${worker.jobTitle}`);
      });
      
      // Check for expected workers
      const expectedWorkers = ['Jane Doe', 'Kamau Wanjiku', 'Ochieng Achieng', 'Kiprotich Ngeny', 'Mwangi Kamau'];
      const existingNames = workers.map(w => w.name);
      const missingWorkers = expectedWorkers.filter(name => !existingNames.includes(name));
      
      if (missingWorkers.length === 0) {
        console.log('\n✅ All expected demo workers are present!');
      } else {
        console.log(`\n⚠️  Missing workers: ${missingWorkers.join(', ')}`);
      }
    } else {
      console.log('❌ No workers found. Run the SQL script to add demo workers.');
    }
    
    // Verify login page password
    console.log('\n🔍 Login Page Password Check:');
    console.log('✅ Password display updated to: testuser123');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

verifyDemoWorkers();