import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { AppModule } from '../../src/app.module';
import { TestDatabaseModule } from '../test-database.module';
import { cleanupTestData } from '../test-utils';
import { DataDeletionService } from '../../src/modules/data-deletion/data-deletion.service';
import { DeletionStatus } from '../../src/modules/data-deletion/entities/deletion-request.entity';
import { WorkersService } from '../../src/modules/workers/workers.service';
import { User } from '../../src/modules/users/entities/user.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

describe('Data Deletion E2E', () => {
    let app: INestApplication;
    let dataDeletionService: DataDeletionService;
    let workersService: WorkersService;
    let userRepo: Repository<User>;
    let workerRepo: Repository<any>;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule, TestDatabaseModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        dataDeletionService = moduleFixture.get<DataDeletionService>(DataDeletionService);
        workersService = moduleFixture.get<WorkersService>(WorkersService);
        userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
        workerRepo = moduleFixture.get<Repository<any>>(getRepositoryToken('Worker'));

        const dataSource = app.get(DataSource);
        await cleanupTestData(dataSource);
    });

    afterAll(async () => {
        if (app) {
            await app.close();
        }
    });

    it('should create and process a data deletion request for a user', async () => {
        // 1. Setup user and data
        const email = 'delete-me@test.com';
        const user = await userRepo.save({
            email,
            passwordHash: 'hash',
            firstName: 'Delete',
            lastName: 'Me',
            countryCode: 'KE',
            isOnboardingCompleted: true,
        });

        await workersService.create(user.id, {
            name: 'To Be Deleted',
            phoneNumber: '+254700000002',
            salaryGross: 30000,
            startDate: '2024-01-01',
        });

        // Verify data exists
        const workerCount = await workerRepo.count({ where: { userId: user.id } });
        expect(workerCount).toBe(1);

        // 2. Create deletion request
        const request = await dataDeletionService.createRequest({
            email,
            reason: 'Testing E2E',
        });

        expect(request.status).toBe(DeletionStatus.PENDING);

        // 3. Process request
        await dataDeletionService.processPendingRequests();

        // 4. Verify data is gone
        const updatedUser = await userRepo.findOne({ where: { id: user.id } });
        expect(updatedUser).toBeNull();

        const updatedWorkerCount = await workerRepo.count({ where: { userId: user.id } });
        expect(updatedWorkerCount).toBe(0);

        const updatedRequest = await dataDeletionService.getRequestStatus(request.id);
        expect(updatedRequest?.status).toBe(DeletionStatus.COMPLETED);
    });
});
