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

async function createTimeEntriesTable() {
  try {
    console.log('🔗 Connecting to database...');
    await AppDataSource.initialize();
    console.log('✅ Database connected');

    // Drop existing table if it exists (to clean up from failed previous attempt)
    console.log('🧹 Cleaning up existing time_entries table...');
    await AppDataSource.query(`DROP TABLE IF EXISTS "time_entries" CASCADE`);

    // Create enum type for TimeEntryStatus
    console.log('📋 Creating enum type for TimeEntryStatus');
    await AppDataSource.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."time_entries_status_enum" AS ENUM ('IN_PROGRESS', 'COMPLETED');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    console.log('🔧 Creating time_entries table...');
    
    const createTableQuery = `
      CREATE TABLE "time_entries" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "workerId" uuid NOT NULL,
        "userId" uuid NOT NULL,
        "propertyId" uuid,
        "clockInTime" TIMESTAMP WITH TIME ZONE NOT NULL,
        "clockOutTime" TIMESTAMP WITH TIME ZONE,
        "clockInLatitude" decimal(10,6),
        "clockInLongitude" decimal(10,6),
        "clockOutLatitude" decimal(10,6),
        "clockOutLongitude" decimal(10,6),
        "totalHours" decimal(5,2),
        "status" "public"."time_entries_status_enum" NOT NULL DEFAULT 'IN_PROGRESS',
        "notes" text,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_time_entries_id" PRIMARY KEY ("id"),
        CONSTRAINT "FK_time_entries_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_time_entries_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE CASCADE
      )
    `;
    
    console.log('   Executing: CREATE TABLE time_entries');
    await AppDataSource.query(createTableQuery);
    
    // Create indexes
    console.log('   Creating indexes for better performance');
    await AppDataSource.query(`CREATE INDEX "idx_time_entries_userId" ON "time_entries" ("userId")`);
    await AppDataSource.query(`CREATE INDEX "idx_time_entries_workerId" ON "time_entries" ("workerId")`);
    await AppDataSource.query(`CREATE INDEX "idx_time_entries_status" ON "time_entries" ("status")`);
    await AppDataSource.query(`CREATE INDEX "idx_time_entries_clockInTime" ON "time_entries" ("clockInTime")`);

    console.log('🎉 time_entries table created successfully!');
    
    // Verify the table was created
    console.log('🔍 Verifying table structure...');
    const tableInfo = await AppDataSource.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'time_entries' 
      ORDER BY ordinal_position;
    `);
    
    console.log('Table columns:');
    tableInfo.forEach(col => {
      console.log(`   ✅ ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(nullable)' : '(not null)'} ${col.column_default ? `(default: ${col.column_default})` : ''}`);
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

createTimeEntriesTable();