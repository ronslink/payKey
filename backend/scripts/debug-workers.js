
const { DataSource } = require('typeorm');
const { Worker } = require('../src/modules/workers/entities/worker.entity'); // Adjust path as needed
const { PayPeriod } = require('../src/modules/payroll/entities/pay-period.entity');
const { PayrollRecord } = require('../src/modules/payroll/entities/payroll-record.entity');
const { User } = require('../src/modules/users/entities/user.entity'); // Add User entity
const { LeaveRequest } = require('../src/modules/workers/entities/leave-request.entity');
const { TimeEntry } = require('../src/modules/time-tracking/entities/time-entry.entity');
const { Transaction } = require('../src/modules/payments/entities/transaction.entity');
const { Activity } = require('../src/modules/activities/entities/activity.entity');

// Database configuration (matching docker-compose usually)
const AppDataSource = new DataSource({
    type: 'postgres',
    host: 'localhost',
    port: 5432,
    username: 'user',
    password: 'password',
    database: 'paykey',
    entities: [Worker, PayPeriod, PayrollRecord, User, LeaveRequest, TimeEntry, Transaction, Activity], // Add all entities
    synchronize: false,
});

async function checkWorkers() {
    try {
        await AppDataSource.initialize();
        console.log('Database connected');

        const userId = '7884ec71-d722-4b68-926e-2cf6a4511703';

        const workers = await AppDataSource.getRepository(Worker).find({
            where: { userId: userId },
        });

        console.log(`Found ${workers.length} workers for user ${userId}`);

        workers.forEach(w => {
            console.log(`Worker: ${w.name}`);
            console.log(`  Payment Method: ${w.paymentMethod}`);
            console.log(`  Bank Name: ${w.bankName}`);
            console.log(`  Bank Code: ${w.bankCode}`);
            console.log(`  Bank Account: ${w.bankAccount}`);
            console.log(`  MPESA Number: ${w.mpesaNumber}`);
            console.log('---');
        });

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
    }
}

checkWorkers();
