const { DataSource } = require('typeorm');
require('dotenv').config({ path: '.env.development' });

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  synchronize: false,
  logging: true,
  entities: [],
  migrations: [],
});

async function addMissingColumns() {
  try {
    console.log('🔗 Connecting to database...');
    await AppDataSource.initialize();
    console.log('✅ Database connected');

    console.log('🔧 Adding missing columns to payroll_records table...');
    
    const queries = [
      `ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "payPeriodId" uuid`,
      `ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "bonuses" decimal(10,2) DEFAULT 0`,
      `ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "otherEarnings" decimal(10,2) DEFAULT 0`,
      `ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "otherDeductions" decimal(10,2) DEFAULT 0`,
      `ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "status" varchar DEFAULT 'draft'`,
      `ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "finalizedAt" TIMESTAMP WITH TIME ZONE`,
    ];

    for (const query of queries) {
      console.log(`   Executing: ${query}`);
      await AppDataSource.query(query);
    }

    console.log('🎉 All columns added successfully!');
    
    // Verify the columns were added
    console.log('🔍 Verifying table structure...');
    const tableInfo = await AppDataSource.query(`
      SELECT column_name, data_type, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'payroll_records' 
      AND column_name IN ('payPeriodId', 'bonuses', 'otherEarnings', 'otherDeductions', 'status', 'finalizedAt')
      ORDER BY column_name;
    `);
    
    console.log('Added columns:');
    tableInfo.forEach(col => {
      console.log(`   ✅ ${col.column_name}: ${col.data_type} (default: ${col.column_default || 'none'})`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
      console.log('🔌 Database disconnected');
    }
  }
}

addMissingColumns();