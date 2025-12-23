import { DataSource, In } from 'typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { LeaveRequest } from '../src/modules/workers/entities/leave-request.entity';
import * as dotenv from 'dotenv';

dotenv.config();

async function checkLeaves() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'paykey',
    entities: [__dirname + '/../modules/**/*.entity.ts'],
    synchronize: false,
  });

  try {
    await dataSource.initialize();
    console.log('Database connected');

    const userRepository = dataSource.getRepository(User);
    const workerRepository = dataSource.getRepository(Worker);
    const leaveRequestRepository = dataSource.getRepository(LeaveRequest);

    const user = await userRepository.findOne({ where: {} });
    if (!user) {
      console.log('No user found');
      return;
    }
    console.log(`Checking leaves for User: ${user.email} (${user.id})`);

    // 1. Get Workers
    const workers = await workerRepository.find({ where: { userId: user.id } });
    console.log(`Found ${workers.length} workers`);
    const workerIds = workers.map((w) => w.id);
    console.log('Worker IDs:', workerIds);

    if (workerIds.length === 0) {
      console.log('No workers, skipping leave check');
      return;
    }

    // 2. Get Leave Requests
    // Mimic the service logic EXACTLY
    console.log('Fetching leave requests...');
    const leaves = await leaveRequestRepository.find({
      where: { workerId: In(workerIds) },
      relations: ['worker', 'approvedBy', 'requestedBy'],
      order: { createdAt: 'DESC' },
    });

    console.log(`Found ${leaves.length} leave requests`);
    if (leaves.length > 0) {
      console.log('Sample Leave Request Structure:');
      console.log(JSON.stringify(leaves[0], null, 2));
    }
  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (dataSource.isInitialized) {
      await dataSource.destroy();
    }
  }
}

checkLeaves();
