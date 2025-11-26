"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const typeorm_1 = require("typeorm");
const worker_entity_1 = require("./modules/workers/entities/worker.entity");
async function addDemoWorkers() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const dataSource = app.get(typeorm_1.DataSource);
    const workerRepository = dataSource.getRepository(worker_entity_1.Worker);
    const demoUserId = '51fdabaa-489b-4c56-9a35-8c63d382d341';
    const existingWorkers = await workerRepository.find({
        where: { userId: demoUserId }
    });
    console.log(`Found ${existingWorkers.length} existing workers for demo user`);
    if (existingWorkers.length > 0) {
        console.log('Existing workers:');
        existingWorkers.forEach(worker => {
            console.log(`- ${worker.name} (${worker.employmentType})`);
        });
    }
    const demoWorkers = [
        {
            userId: demoUserId,
            name: 'Lex Luther',
            phoneNumber: '+254700123456',
            salaryGross: 15000.00,
            startDate: new Date('2024-01-15'),
            employmentType: worker_entity_1.EmploymentType.FIXED,
            isActive: true,
            paymentFrequency: worker_entity_1.PaymentFrequency.MONTHLY,
            jobTitle: 'Accountant',
            hourlyRate: 86.54,
            housingAllowance: 0,
            transportAllowance: 0,
            mpesaNumber: '+254700123456'
        },
        {
            userId: demoUserId,
            name: 'Kamau Wanjiku',
            phoneNumber: '+254700234567',
            salaryGross: 120000.00,
            startDate: new Date('2024-02-01'),
            employmentType: worker_entity_1.EmploymentType.FIXED,
            isActive: true,
            paymentFrequency: worker_entity_1.PaymentFrequency.MONTHLY,
            jobTitle: 'Manager',
            hourlyRate: 692.31,
            housingAllowance: 15000,
            transportAllowance: 8000,
            mpesaNumber: '+254700234567'
        },
        {
            userId: demoUserId,
            name: 'Ochieng Achieng',
            phoneNumber: '+254700345678',
            salaryGross: 120000.00,
            startDate: new Date('2024-03-01'),
            employmentType: worker_entity_1.EmploymentType.FIXED,
            isActive: true,
            paymentFrequency: worker_entity_1.PaymentFrequency.MONTHLY,
            jobTitle: 'Developer',
            hourlyRate: 692.31,
            housingAllowance: 12000,
            transportAllowance: 5000,
            mpesaNumber: '+254700345678'
        },
        {
            userId: demoUserId,
            name: 'Kiprotich Ngeny',
            phoneNumber: '+254700456789',
            salaryGross: 10000.00,
            startDate: new Date('2024-04-01'),
            employmentType: worker_entity_1.EmploymentType.HOURLY,
            isActive: true,
            paymentFrequency: worker_entity_1.PaymentFrequency.WEEKLY,
            jobTitle: 'Contractor',
            hourlyRate: 200.00,
            housingAllowance: 0,
            transportAllowance: 0,
            mpesaNumber: '+254700456789'
        },
        {
            userId: demoUserId,
            name: 'Mwangi Kamau',
            phoneNumber: '+254700567890',
            salaryGross: 120000.00,
            startDate: new Date('2024-05-01'),
            employmentType: worker_entity_1.EmploymentType.FIXED,
            isActive: true,
            paymentFrequency: worker_entity_1.PaymentFrequency.MONTHLY,
            jobTitle: 'Supervisor',
            hourlyRate: 692.31,
            housingAllowance: 10000,
            transportAllowance: 6000,
            mpesaNumber: '+254700567890'
        }
    ];
    let addedCount = 0;
    for (const workerData of demoWorkers) {
        const existingWorker = existingWorkers.find(w => w.name === workerData.name);
        if (!existingWorker) {
            const newWorker = workerRepository.create(workerData);
            await workerRepository.save(newWorker);
            console.log(`Added worker: ${workerData.name}`);
            addedCount++;
        }
        else {
            console.log(`Worker already exists: ${workerData.name}`);
        }
    }
    console.log(`\nSummary: ${addedCount} new workers added`);
    console.log(`Total workers for demo user: ${existingWorkers.length + addedCount}`);
    await app.close();
}
addDemoWorkers().catch(console.error);
//# sourceMappingURL=add-demo-workers.js.map