"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const users_service_1 = require("./modules/users/users.service");
const workers_service_1 = require("./modules/workers/workers.service");
const user_entity_1 = require("./modules/users/entities/user.entity");
const worker_entity_1 = require("./modules/workers/entities/worker.entity");
const typeorm_1 = require("@nestjs/typeorm");
const bcrypt = __importStar(require("bcrypt"));
async function seedTestData() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    try {
        const usersService = app.get(users_service_1.UsersService);
        const workersService = app.get(workers_service_1.WorkersService);
        const userRepo = app.get((0, typeorm_1.getRepositoryToken)(user_entity_1.User));
        const workerRepo = app.get((0, typeorm_1.getRepositoryToken)(worker_entity_1.Worker));
        console.log('🌱 Seeding test data...');
        await workerRepo.delete({ userId: 'test-user-123' });
        await workerRepo.delete({ userId: 'loadtest-user-123' });
        await workerRepo.delete({ userId: 'performance-test-123' });
        await userRepo.delete({ email: 'test@paykey.com' });
        await userRepo.delete({ email: 'loadtest@paykey.com' });
        await userRepo.delete({ email: 'performance-test@paykey.com' });
        const testUsers = [
            {
                email: 'test@paykey.com',
                password: 'test-password',
                firstName: 'Test',
                lastName: 'User',
                countryCode: 'KE',
                isOnboardingCompleted: true,
            },
            {
                email: 'loadtest@paykey.com',
                password: 'password123',
                firstName: 'Load',
                lastName: 'Test',
                countryCode: 'KE',
                isOnboardingCompleted: true,
            },
            {
                email: 'performance-test@paykey.com',
                password: 'test-password',
                firstName: 'Performance',
                lastName: 'Test',
                countryCode: 'KE',
                isOnboardingCompleted: true,
            },
        ];
        for (const userData of testUsers) {
            const hashedPassword = await bcrypt.hash(userData.password, 10);
            const user = await userRepo.save({
                email: userData.email,
                passwordHash: hashedPassword,
                firstName: userData.firstName,
                lastName: userData.lastName,
                countryCode: userData.countryCode,
                isOnboardingCompleted: userData.isOnboardingCompleted,
            });
            console.log(`✅ Created test user: ${user.email} (${user.id})`);
            const workerCount = userData.email.includes('performance') ? 100 : 50;
            const workers = [];
            for (let i = 0; i < workerCount; i++) {
                const worker = await workersService.create(user.id, {
                    name: `${userData.firstName} Worker ${i + 1}`,
                    phoneNumber: `+25471234567${(i % 10).toString()}`,
                    email: `worker${i + 1}@example.com`,
                    salaryGross: 30000 + (i * 1000),
                    startDate: '2024-01-01',
                    jobTitle: `Position ${i + 1}`,
                    employmentType: worker_entity_1.EmploymentType.FIXED,
                    paymentFrequency: worker_entity_1.PaymentFrequency.MONTHLY,
                    paymentMethod: i % 2 === 0 ? worker_entity_1.PaymentMethod.BANK : worker_entity_1.PaymentMethod.MPESA,
                    bankName: i % 2 === 0 ? 'KCB Bank' : undefined,
                    bankAccount: i % 2 === 0 ? `1234567890${i.toString().padStart(3, '0')}` : undefined,
                    mpesaNumber: i % 2 === 1 ? `+25471234567${(i % 10).toString()}` : undefined,
                });
                workers.push(worker);
            }
            console.log(`✅ Created ${workers.length} workers for ${user.email}`);
        }
        const complianceUser = await userRepo.save({
            email: 'compliance-test@paykey.com',
            passwordHash: await bcrypt.hash('test-password', 10),
            firstName: 'Compliance',
            lastName: 'Test',
            countryCode: 'KE',
            isOnboardingCompleted: true,
        });
        const complianceWorkers = [
            { salary: 10000, name: 'Low Salary Worker' },
            { salary: 25000, name: 'Threshold Worker' },
            { salary: 35000, name: 'Mid Range Worker' },
            { salary: 60000, name: 'High Salary Worker' },
            { salary: 120000, name: 'Very High Salary Worker' },
            { salary: 200000, name: 'Executive Worker' },
            { salary: 500000, name: 'Top Bracket Worker' },
        ];
        for (const workerData of complianceWorkers) {
            await workersService.create(complianceUser.id, {
                name: workerData.name,
                phoneNumber: '+254712345670',
                salaryGross: workerData.salary,
                startDate: '2024-01-01',
                jobTitle: 'Test Position',
                employmentType: worker_entity_1.EmploymentType.FIXED,
                paymentFrequency: worker_entity_1.PaymentFrequency.MONTHLY,
                paymentMethod: worker_entity_1.PaymentMethod.BANK,
                bankName: 'KCB Bank',
                bankAccount: '1234567890',
            });
        }
        console.log('✅ Created compliance test workers');
        console.log('🎉 Test data seeding completed successfully!');
        console.log('\n📊 Summary:');
        console.log('- 3 test users created');
        console.log('- 200 test workers created');
        console.log('- 7 compliance test workers created');
        console.log('- All with realistic Kenyan payroll data');
    }
    catch (error) {
        console.error('❌ Error seeding test data:', error);
        throw error;
    }
    finally {
        await app.close();
    }
}
seedTestData().catch(console.error);
//# sourceMappingURL=seed-test-data.js.map