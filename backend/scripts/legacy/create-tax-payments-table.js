const { Pool } = require('pg');

// Create connection to database
const pool = new Pool({
  user: 'ronon',
  host: 'localhost',
  database: 'paykey',
  port: 5432,
});

async function createTable() {
  const client = await pool.connect();
  
  try {
    console.log('Creating tax_payments table...');
    
    // Create enum types
    await client.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."tax_payments_tax_type_enum" AS ENUM('PAYE', 'NSSF_TIER1', 'NSSF_TIER2', 'NHIF', 'HOUSING_LEVY', 'SHIF');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);
    
    await client.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."tax_payments_payment_method_enum" AS ENUM('MPESA', 'BANK');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);
    
    await client.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."tax_payments_status_enum" AS ENUM('PENDING', 'PAID', 'OVERDUE');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);
    
    // Create table
    await client.query(`
      CREATE TABLE IF NOT EXISTS "tax_payments" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" uuid NOT NULL,
        "taxType" "public"."tax_payments_tax_type_enum" NOT NULL,
        "paymentYear" integer NOT NULL,
        "paymentMonth" integer NOT NULL,
        "amount" numeric(12,2) NOT NULL DEFAULT 0,
        "paymentDate" date,
        "paymentMethod" "public"."tax_payments_payment_method_enum",
        "receiptNumber" character varying,
        "status" "public"."tax_payments_status_enum" NOT NULL DEFAULT 'PENDING',
        "notes" text,
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_90f8c1c6e04d3d8e8e8b2b2b2b" PRIMARY KEY ("id")
      );
    `);
    
    // Create index
    await client.query(`
      CREATE INDEX IF NOT EXISTS "IDX_6cc3c9b8b3d5c3c3c3c3c3c3c" ON "tax_payments" ("userId");
    `);
    
    // Create foreign key constraint
    await client.query(`
      ALTER TABLE "tax_payments" 
      ADD CONSTRAINT "FK_8c8c8c8c8c8c8c8c8c8c8c8c8" 
      FOREIGN KEY ("userId") 
      REFERENCES "users"("id") 
      ON DELETE NO ACTION 
      ON UPDATE NO ACTION;
    `);
    
    console.log('✅ tax_payments table created successfully!');
    
  } catch (error) {
    console.error('❌ Error creating table:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

createTable();