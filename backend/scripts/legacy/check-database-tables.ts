import { DataSource } from 'typeorm';

// Use the same configuration as the migrations
const dataSource = new DataSource({
  type: 'postgres',
  host: 'localhost',
  port: 5435,
  username: 'postgres',
  password: 'admin',
  database: 'paykey',
  synchronize: false,
  entities: [],
  logging: true,
});

async function listTables() {
  try {
    await dataSource.initialize();
    console.log('Connected to database successfully!');
    
    const query = `
      SELECT table_name, table_schema 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `;
    
    const result: any[] = await dataSource.query(query);
    
    console.log('\n📊 Current Database Tables:');
    console.log('='.repeat(50));
    
    result.forEach((row: any, index: number) => {
      console.log(`${index + 1}. ${row.table_name} (${row.table_schema})`);
    });
    
    console.log(`\nTotal tables: ${result.length}`);
    
    // Check for specific tables we're looking for
    const tableNames: string[] = result.map((row: any) => row.table_name);
    const targetTables = [
      'leave_requests',
      'terminations', 
      'account_mappings',
      'accounting_exports',
      'tax_payments'
    ];
    
    console.log('\n🎯 Missing Tables Status:');
    console.log('='.repeat(50));
    
    targetTables.forEach((table: string) => {
      if (tableNames.includes(table)) {
        console.log(`✅ ${table} - EXISTS`);
      } else {
        console.log(`❌ ${table} - MISSING`);
      }
    });
    
  } catch (error: any) {
    console.error('Error connecting to database:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

listTables();