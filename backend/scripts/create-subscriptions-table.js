const { Pool } = require('pg');

async function createSubscriptionsTable() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'admin',
    database: process.env.DB_NAME || 'paykey',
  });

  try {
    console.log('🔧 Creating subscriptions table...');
    
    // Create the subscriptions table
    const createTableQuery = `
      CREATE TABLE IF NOT EXISTS "subscriptions" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" uuid NOT NULL,
        "tier" varchar NOT NULL CHECK ("tier" IN ('FREE', 'BASIC', 'GOLD', 'PLATINUM')),
        "status" varchar NOT NULL DEFAULT 'ACTIVE' CHECK ("status" IN ('ACTIVE', 'CANCELLED', 'EXPIRED', 'PAST_DUE', 'TRIAL')),
        "amount" decimal(10,2) NULL,
        "currency" varchar NOT NULL DEFAULT 'USD',
        "startDate" timestamptz NULL,
        "endDate" timestamptz NULL,
        "nextBillingDate" timestamptz NULL,
        "stripeSubscriptionId" varchar NULL,
        "stripePriceId" varchar NULL,
        "notes" text NULL,
        "createdAt" timestamptz NOT NULL DEFAULT now(),
        "updatedAt" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "PK_subscriptions_id" PRIMARY KEY ("id")
      );
    `;

    await pool.query(createTableQuery);
    console.log('✅ Subscriptions table created successfully');
    
    // Create foreign key constraint
    const createFKQuery = `
      ALTER TABLE "subscriptions" 
      ADD CONSTRAINT "FK_subscriptions_userId" 
      FOREIGN KEY ("userId") REFERENCES "users"("id") 
      ON DELETE CASCADE;
    `;

    await pool.query(createFKQuery);
    console.log('✅ Foreign key constraint added successfully');
    
    // Create indexes
    const createIndexQueries = [
      `CREATE INDEX IF NOT EXISTS "idx_subscriptions_userId" ON "subscriptions" ("userId");`,
      `CREATE INDEX IF NOT EXISTS "idx_subscriptions_status" ON "subscriptions" ("status");`,
      `CREATE INDEX IF NOT EXISTS "idx_subscriptions_tier" ON "subscriptions" ("tier");`,
    ];

    for (const query of createIndexQueries) {
      await pool.query(query);
    }
    console.log('✅ Indexes created successfully');
    
    // Insert a demo subscription for the test user
    const insertDemoQuery = `
      INSERT INTO "subscriptions" ("userId", "tier", "status", "amount", "currency", "notes")
      VALUES (
        '51fdabaa-489b-4c56-9a35-8c63d382d341',
        'BASIC',
        'ACTIVE',
        29.99,
        'USD',
        'Demo subscription for testing'
      )
      ON CONFLICT DO NOTHING;
    `;

    await pool.query(insertDemoQuery);
    console.log('✅ Demo subscription inserted');
    
    console.log('\n🎉 Subscriptions table setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Error creating subscriptions table:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  createSubscriptionsTable()
    .then(() => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error.message);
      process.exit(1);
    });
}

module.exports = { createSubscriptionsTable };
