import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { AppModule } from '../../src/app.module';
import { TestDatabaseModule } from '../test-database.module';
import { cleanupTestData } from '../test-utils';
import { User } from '../../src/modules/users/entities/user.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

describe('Export Module E2E', () => {
    let app: INestApplication;
    let userRepo: Repository<User>;
    let testUser: User;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule, TestDatabaseModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));

        const dataSource = app.get(DataSource);
        await cleanupTestData(dataSource);

        testUser = await userRepo.save({
            email: 'export-test@paykey.com',
            passwordHash: 'hash',
            firstName: 'Export',
            lastName: 'Tester',
            countryCode: 'KE',
            isOnboardingCompleted: true,
        });
    });

    afterAll(async () => {
        if (app) {
            await app.close();
        }
    });

    it('should be able to initialize the export module', async () => {
        // Basic verification of module connectivity
        expect(app).toBeDefined();
        expect(testUser).toBeDefined();
    });
});
