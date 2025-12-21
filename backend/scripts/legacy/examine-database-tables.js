const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function examineAllTables() {
  try {
    await client.connect();
    console.log('🔍 Examining all tables in database...\n');
    
    // List all tables to understand the schema
    const allTables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    console.log('📋 All tables in database:');
    allTables.rows.forEach(table => {
      console.log(`   • ${table.table_name}`);
    });
    
    // Focus on tax and payment related
    const taxRelatedTables = allTables.rows
      .filter(row => row.table_name.includes('tax') || row.table_name.includes('payment'))
      .map(row => row.table_name);
    
    console.log('\n📋 Tax/Payment related tables:');
    if (taxRelatedTables.length === 0) {
      console.log('   ❌ No tax/payment tables found');
    } else {
      taxRelatedTables.forEach(table => {
        console.log(`   • ${table}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

examineAllTables();