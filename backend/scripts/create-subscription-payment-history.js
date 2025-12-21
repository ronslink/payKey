const { Pool } = require('pg');

async function createSubscriptionPaymentHistory() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'admin',
    database: process.env.DB_NAME || 'paykey',
  });

  try {
    console.log('💳 Creating subscription payment history table...');
    
    // Create the subscription payment history table
    const createTableQuery = `
      CREATE TABLE IF NOT EXISTS "subscription_payments" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "subscriptionId" uuid NOT NULL,
        "userId" uuid NOT NULL,
        "amount" decimal(10,2) NOT NULL,
        "currency" varchar NOT NULL DEFAULT 'USD',
        "status" varchar NOT NULL DEFAULT 'COMPLETED' CHECK ("status" IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
        "paymentMethod" varchar NOT NULL,
        "billingPeriod" varchar NOT NULL,
        "periodStart" timestamptz NOT NULL,
        "periodEnd" timestamptz NOT NULL,
        "dueDate" timestamptz NOT NULL,
        "paidDate" timestamptz NULL,
        "invoiceNumber" varchar NULL,
        "paymentProvider" varchar NULL,
        "transactionId" varchar NULL,
        "metadata" jsonb NULL,
        "notes" text NULL,
        "createdAt" timestamptz NOT NULL DEFAULT now(),
        "updatedAt" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "PK_subscription_payments_id" PRIMARY KEY ("id")
      );
    `;

    await pool.query(createTableQuery);
    console.log('✅ Subscription payments table created successfully');
    
    // Create foreign key constraints
    const createFKQueries = [
      `ALTER TABLE "subscription_payments" 
       ADD CONSTRAINT "FK_subscription_payments_subscriptionId" 
       FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") 
       ON DELETE CASCADE;`,
      `ALTER TABLE "subscription_payments" 
       ADD CONSTRAINT "FK_subscription_payments_userId" 
       FOREIGN KEY ("userId") REFERENCES "users"("id") 
       ON DELETE CASCADE;`
    ];

    for (const query of createFKQueries) {
      await pool.query(query);
    }
    console.log('✅ Foreign key constraints added successfully');
    
    // Create indexes
    const createIndexQueries = [
      `CREATE INDEX IF NOT EXISTS "idx_subscription_payments_subscriptionId" ON "subscription_payments" ("subscriptionId");`,
      `CREATE INDEX IF NOT EXISTS "idx_subscription_payments_userId" ON "subscription_payments" ("userId");`,
      `CREATE INDEX IF NOT EXISTS "idx_subscription_payments_status" ON "subscription_payments" ("status");`,
      `CREATE INDEX IF NOT EXISTS "idx_subscription_payments_period" ON "subscription_payments" ("periodStart", "periodEnd");`,
      `CREATE INDEX IF NOT EXISTS "idx_subscription_payments_dueDate" ON "subscription_payments" ("dueDate");`,
    ];

    for (const query of createIndexQueries) {
      await pool.query(query);
    }
    console.log('✅ Indexes created successfully');
    
    // Insert demo payment history for the test user
    const subscriptionId = 'f9d14377-9ed9-42b9-89fa-ece781c733b6'; // From our demo subscription
    const userId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    
    const insertDemoPaymentsQuery = `
      INSERT INTO "subscription_payments" 
      ("subscriptionId", "userId", "amount", "currency", "status", "paymentMethod", "billingPeriod", 
       "periodStart", "periodEnd", "dueDate", "paidDate", "invoiceNumber", "paymentProvider", 
       "transactionId", "metadata", "notes")
      VALUES 
      -- Current month payment
      ($1, $2, 29.99, 'USD', 'COMPLETED', 'Credit Card', 'monthly', 
       '2025-11-01 00:00:00+00', '2025-11-30 23:59:59+00', '2025-11-01 00:00:00+00', 
       '2025-11-01 10:30:00+00', 'INV-2025-001', 'stripe', 'ch_3P8xYhKqgO2xYz', 
       '{"plan": "BASIC", "workers": 10}', 'Monthly BASIC plan payment'),
      
      -- Previous month payment
      ($1, $2, 29.99, 'USD', 'COMPLETED', 'Credit Card', 'monthly',
       '2025-10-01 00:00:00+00', '2025-10-31 23:59:59+00', '2025-10-01 00:00:00+00',
       '2025-10-01 14:15:00+00', 'INV-2025-002', 'stripe', 'ch_3P8xYhKqgO2xYz',
       '{"plan": "BASIC", "workers": 10}', 'Monthly BASIC plan payment'),
      
      -- Two months ago payment
      ($1, $2, 29.99, 'USD', 'COMPLETED', 'Credit Card', 'monthly',
       '2025-09-01 00:00:00+00', '2025-09-30 23:59:59+00', '2025-09-01 00:00:00+00',
       '2025-09-01 09:45:00+00', 'INV-2025-003', 'stripe', 'ch_3P7xYhKqgO2xYz',
       '{"plan": "BASIC", "workers": 8}', 'Monthly BASIC plan payment'),
      
      -- Three months ago payment  
      ($1, $2, 29.99, 'USD', 'COMPLETED', 'Credit Card', 'monthly',
       '2025-08-01 00:00:00+00', '2025-08-31 23:59:59+00', '2025-08-01 00:00:00+00',
       '2025-08-01 16:20:00+00', 'INV-2025-004', 'stripe', 'ch_3P6xYhKqgO2xYz',
       '{"plan": "BASIC", "workers": 8}', 'Monthly BASIC plan payment'),
      
      -- Six months ago payment
      ($1, $2, 19.99, 'USD', 'COMPLETED', 'Credit Card', 'monthly',
       '2025-05-01 00:00:00+00', '2025-05-31 23:59:59+00', '2025-05-01 00:00:00+00',
       '2025-05-01 11:10:00+00', 'INV-2025-005', 'stripe', 'ch_3P5xYhKqgO2xYz',
       '{"plan": "BASIC", "workers": 5}', 'Monthly BASIC plan payment'),
      
      -- Failed payment example
      ($1, $2, 29.99, 'USD', 'FAILED', 'Credit Card', 'monthly',
       '2025-04-01 00:00:00+00', '2025-04-30 23:59:59+00', '2025-04-01 00:00:00+00',
       NULL, 'INV-2025-006', 'stripe', NULL,
       '{"plan": "BASIC", "workers": 10}', 'Payment failed - insufficient funds'),
      
      -- Pending payment example
      ($1, $2, 29.99, 'USD', 'PENDING', 'Bank Transfer', 'monthly',
       '2025-03-01 00:00:00+00', '2025-03-31 23:59:59+00', '2025-03-01 00:00:00+00',
       NULL, 'INV-2025-007', 'bank_transfer', 'TXN-20250301-BANK',
       '{"plan": "BASIC", "workers": 10}', 'Pending bank transfer'),
       
      -- First payment
      ($1, $2, 29.99, 'USD', 'COMPLETED', 'Credit Card', 'monthly',
       '2025-01-01 00:00:00+00', '2025-01-31 23:59:59+00', '2025-01-01 00:00:00+00',
       '2025-01-01 12:00:00+00', 'INV-2025-008', 'stripe', 'ch_3P1xYhKqgO2xYz',
       '{"plan": "BASIC", "workers": 3}', 'First BASIC plan payment')
       
      ON CONFLICT DO NOTHING;
    `;

    await pool.query(insertDemoPaymentsQuery, [subscriptionId, userId]);
    console.log('✅ Demo payment history inserted');
    
    console.log('\n🎉 Subscription payment history table setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Error creating subscription payment history:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  createSubscriptionPaymentHistory()
    .then(() => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error.message);
      process.exit(1);
    });
}

module.exports = { createSubscriptionPaymentHistory };
