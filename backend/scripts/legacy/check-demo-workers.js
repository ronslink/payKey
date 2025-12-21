async function checkWorkers() {
  try {
    console.log('Checking demo workers...');
    
    // Login to get token
    const loginResponse = await fetch('http://localhost:3000/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'testuser@paykey.com', password: 'testuser123' })
    });
    
    if (!loginResponse.ok) {
      console.log('Login failed:', loginResponse.status, loginResponse.statusText);
      const loginError = await loginResponse.text();
      console.log('Login error:', loginError);
      return;
    }
    
    const { access_token } = await loginResponse.json();
    console.log('Login successful, got token');
    
    // Get workers
    const workersResponse = await fetch('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${access_token}` }
    });
    
    if (!workersResponse.ok) {
      console.log('Workers fetch failed:', workersResponse.status, workersResponse.statusText);
      const workersError = await workersResponse.text();
      console.log('Workers error:', workersError);
      return;
    }
    
    const workers = await workersResponse.json();
    console.log('Current workers count:', Array.isArray(workers) ? workers.length : 'Not an array');
    console.log('Workers data:', JSON.stringify(workers, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkWorkers();