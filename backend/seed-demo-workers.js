const axios = require('axios');

async function seedDemoWorkers() {
  try {
    console.log('🔍 Starting demo workers check and seeding...');
    
    // Login first
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    // Check existing workers
    const workersResponse = await axios.get('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    const existingWorkers = workersResponse.data;
    console.log(`📊 Found ${existingWorkers.length} existing workers`);
    
    if (existingWorkers.length === 0) {
      console.log('🌟 Seeding demo employees...');
      
      // Add demo employees
      const demoWorkers = [
        {
          name: 'Jane Wanjiku',
          phoneNumber: '+254722123456',
          idNumber: '12345678',
          kraPin: 'A001234567A',
          salaryGross: 85000,
          jobTitle: 'Software Engineer',
          employmentType: 'FIXED',
          paymentFrequency: 'MONTHLY',
          paymentMethod: 'bank',
          bankName: 'KCB Bank',
          bankAccount: '1234567890',
          startDate: '2024-01-01',
          email: 'jane.wanjiku@example.com',
          nssfNumber: '12345678901',
          nhifNumber: '87654321',
          isActive: true
        },
        {
          name: 'Peter Mwangi',
          phoneNumber: '+254733234567',
          idNumber: '23456789',
          kraPin: 'B002345678B',
          salaryGross: 95000,
          jobTitle: 'Marketing Manager',
          employmentType: 'FIXED',
          paymentFrequency: 'MONTHLY',
          paymentMethod: 'mpesa',
          mpesaNumber: '+254733234567',
          startDate: '2024-02-01',
          email: 'peter.mwangi@example.com',
          nssfNumber: '23456789012',
          nhifNumber: '76543210',
          isActive: true
        },
        {
          name: 'Grace Akinyi',
          phoneNumber: '+254744345678',
          idNumber: '34567890',
          kraPin: 'C003456789C',
          salaryGross: 75000,
          jobTitle: 'HR Specialist',
          employmentType: 'FIXED',
          paymentFrequency: 'MONTHLY',
          paymentMethod: 'bank',
          bankName: 'Equity Bank',
          bankAccount: '0987654321',
          startDate: '2024-01-15',
          email: 'grace.akinyi@example.com',
          nssfNumber: '34567890123',
          nhifNumber: '65432109',
          isActive: true
        },
        {
          name: 'David Kiprotich',
          phoneNumber: '+254755456789',
          idNumber: '45678901',
          kraPin: 'D004567890D',
          salaryGross: 65000,
          jobTitle: 'Sales Representative',
          employmentType: 'HOURLY',
          hourlyRate: 400,
          paymentFrequency: 'MONTHLY',
          paymentMethod: 'mpesa',
          mpesaNumber: '+254755456789',
          startDate: '2024-03-01',
          email: 'david.kiprotich@example.com',
          nssfNumber: '45678901234',
          nhifNumber: '54321098',
          isActive: true
        },
        {
          name: 'Mary Chebet',
          phoneNumber: '+254766567890',
          idNumber: '56789012',
          kraPin: 'E005678901E',
          salaryGross: 80000,
          jobTitle: 'Accountant',
          employmentType: 'FIXED',
          paymentFrequency: 'MONTHLY',
          paymentMethod: 'bank',
          bankName: 'Co-operative Bank',
          bankAccount: '1122334455',
          startDate: '2024-01-10',
          email: 'mary.chebet@example.com',
          nssfNumber: '56789012345',
          nhifNumber: '43210987',
          isActive: true
        }
      ];
      
      for (const worker of demoWorkers) {
        try {
          const createResponse = await axios.post('http://localhost:3000/workers', worker, {
            headers: { 'Authorization': `Bearer ${token}` }
          });
          
          if (createResponse.status === 201) {
            console.log(`✅ Added worker: ${worker.name}`);
          }
        } catch (error) {
          console.log(`❌ Failed to add worker ${worker.name}:`, error.response?.data?.message || error.message);
        }
      }
      
      // Verify final count
      const finalResponse = await axios.get('http://localhost:3000/workers', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      console.log(`🎉 Demo workers setup complete! Total workers: ${finalResponse.data.length}`);
      
    } else {
      console.log('✅ Demo employees already exist:');
      existingWorkers.forEach((worker, index) => {
        console.log(`${index + 1}. ${worker.name} - ${worker.employmentType}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error during demo workers setup:', error.message);
  }
}

// Wait for server to be ready
setTimeout(seedDemoWorkers, 3000);