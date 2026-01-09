const { getRepository } = require('typeorm');
const { Transaction } = require('./src/modules/transactions/entities/transaction.entity');
const { User } = require('./src/modules/users/entities/user.entity');
const { DataSource } = require('typeorm');

// Database connection configuration
const dataSource = new DataSource({
  type: 'postgres',
  host: 'localhost',
  port: 5432,
  username: 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  database: 'paykey',
  entities: [Transaction, User],
  synchronize: false,
  logging: true,
});

async function seedTransactions() {
  try {
    await dataSource.initialize();
    console.log('✅ Database connected');

    // Get the demo user
    const userRepository = getRepository(User);
    const transactionRepository = getRepository(Transaction);

    const demoUser = await userRepository.findOne({
      where: { email: 'testuser@paykey.com' }
    });

    if (!demoUser) {
      console.log('❌ Demo user not found');
      return;
    }

    console.log('👤 Found demo user:', demoUser.email);

    // Check if transactions already exist
    const existingTransactions = await transactionRepository.find({
      where: { userId: demoUser.id }
    });

    if (existingTransactions.length > 0) {
      console.log(`✅ ${existingTransactions.length} transactions already exist for user`);
      return;
    }

    // Create sample transactions
    const sampleTransactions = [
      {
        id: 'txn_' + Date.now() + '_1',
        userId: demoUser.id,
        amount: 9.99,
        currency: 'USD',
        status: 'succeeded',
        paymentMethod: 'stripe',
        createdAt: new Date('2025-11-20T10:30:00Z'),
        succeededAt: new Date('2025-11-20T10:30:05Z'),
        invoiceUrl: 'https://paykey.com/invoices/inv_001',
        stripePaymentIntentId: 'pi_1234567890',
        metadata: { planTier: 'BASIC', subscriptionId: 'sub_123456' }
      },
      {
        id: 'txn_' + Date.now() + '_2',
        userId: demoUser.id,
        amount: 1200,
        currency: 'KES',
        status: 'succeeded',
        paymentMethod: 'mpesa',
        createdAt: new Date('2025-11-18T14:45:00Z'),
        succeededAt: new Date('2025-11-18T14:45:12Z'),
        mpesaTransactionId: 'M1234567890',
        metadata: { planTier: 'BASIC', mpesaRef: 'MP_REF_123' }
      },
      {
        id: 'txn_' + Date.now() + '_3',
        userId: demoUser.id,
        amount: 0,
        currency: 'USD',
        status: 'succeeded',
        paymentMethod: 'stripe',
        createdAt: new Date('2025-11-15T09:15:00Z'),
        succeededAt: new Date('2025-11-15T09:15:02Z'),
        invoiceUrl: 'https://paykey.com/invoices/inv_000',
        metadata: { planTier: 'FREE', subscriptionId: 'sub_free' }
      }
    ];

    for (const transactionData of sampleTransactions) {
      const transaction = transactionRepository.create(transactionData);
      await transactionRepository.save(transaction);
      console.log(`✅ Created transaction: ${transaction.id} - ${transaction.amount} ${transaction.currency}`);
    }

    console.log(`🎉 Successfully seeded ${sampleTransactions.length} transactions`);

  } catch (error) {
    console.error('❌ Error seeding transactions:', error);
  } finally {
    if (dataSource.isInitialized) {
      await dataSource.destroy();
    }
  }
}

seedTransactions();
