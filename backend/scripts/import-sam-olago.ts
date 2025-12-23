import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/modules/auth/auth.service';
import { UsersService } from '../src/modules/users/users.service';
import { WorkersService } from '../src/modules/workers/workers.service';
import { PropertiesService } from '../src/modules/properties/properties.service';
import { PayPeriodsService } from '../src/modules/pay-periods/pay-periods.service';
import { PayrollService } from '../src/modules/payroll/payroll.service';
import * as fs from 'fs';
import * as path from 'path';

// Load extracted data
const extractedDataPath = path.join(__dirname, '../../extracted_data.json');
const extractedData = JSON.parse(fs.readFileSync(extractedDataPath, 'utf-8'));

async function importSamOlagoData() {
    console.log('🚀 Starting Sam Olago data import...\n');

    const app = await NestFactory.createApplicationContext(AppModule);

    const authService = app.get(AuthService);
    const usersService = app.get(UsersService);
    const workersService = app.get(WorkersService);
    const propertiesService = app.get(PropertiesService);
    const payPeriodsService = app.get(PayPeriodsService);
    const payrollService = app.get(PayrollService);

    try {
        // Step 1: Create or get Sam Olago user
        console.log('👤 Step 1: Creating Sam Olago user account...');
        let samUser;

        try {
            samUser = await usersService.findByEmail('kingpublish@gmail.com');
            console.log('   ✅ User already exists');
        } catch {
            const registerResult = await authService.register({
                email: 'kingpublish@gmail.com',
                password: 'Sam2026test!',
                name: 'Sam Olago',
            });
            samUser = await usersService.findByEmail('kingpublish@gmail.com');
            console.log('   ✅ User created successfully');
        }

        // Step 2: Create property
        console.log('\n🏢 Step 2: Creating property...');
        let property;

        const existingProperties = await propertiesService.findAll(samUser.id);
        property = existingProperties.find(p => p.name.includes('UNON'));

        if (!property) {
            property = await propertiesService.create(samUser.id, {
                name: 'Samuel Olago - UNON',
                address: 'P.O. Box 67578 Nairobi 00200 Kenya',
                propertyType: 'RESIDENTIAL',
            });
            console.log('   ✅ Property created');
        } else {
            console.log('   ✅ Property already exists');
        }

        // Step 3: Create workers
        console.log('\n👷 Step 3: Creating workers...');
        const workerMap = new Map();

        for (const workerData of extractedData.workers) {
            const existingWorkers = await workersService.findAll(samUser.id);
            let worker = existingWorkers.find(w => w.kraPin === workerData.pin);

            if (!worker) {
                worker = await workersService.create(samUser.id, {
                    name: workerData.name,
                    phoneNumber: '+254700000000', // Placeholder
                    idNumber: workerData.id_no,
                    kraPin: workerData.pin,
                    nssfNumber: workerData.nssf,
                    nhifNumber: workerData.nhif,
                    jobTitle: workerData.job_title,
                    salaryGross: parseFloat(workerData.basic_pay),
                    employmentType: 'FIXED',
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'CASH',
                    startDate: new Date('2024-01-01'),
                    isActive: true,
                    propertyId: property.id,
                });
                console.log(`   ✅ Created worker: ${workerData.name}`);
            } else {
                console.log(`   ✅ Worker already exists: ${workerData.name}`);
            }

            workerMap.set(workerData.name, worker);
        }

        // Step 4: Create historical payroll records
        console.log('\n📊 Step 4: Creating historical payroll records...');

        const monthOrder = {
            'January': 1, 'February': 2, 'March': 3, 'April': 4,
            'May': 5, 'June': 6, 'July': 7, 'August': 8,
            'September': 9, 'October': 10, 'November': 11, 'December': 12
        };

        // Sort payroll history chronologically
        const sortedHistory = extractedData.payroll_history.sort((a, b) => {
            const yearDiff = parseInt(a.year) - parseInt(b.year);
            if (yearDiff !== 0) return yearDiff;
            return monthOrder[a.month] - monthOrder[b.month];
        });

        for (const period of sortedHistory) {
            const monthNum = monthOrder[period.month];
            const year = parseInt(period.year);

            const periodStart = new Date(year, monthNum - 1, 1);
            const periodEnd = new Date(year, monthNum, 0);

            console.log(`\n   Processing ${period.month} ${period.year}...`);

            // Check if pay period already exists
            const existingPeriods = await payPeriodsService.findAll(samUser.id);
            let payPeriod = existingPeriods.find(p =>
                p.periodStart.getTime() === periodStart.getTime() &&
                p.periodEnd.getTime() === periodEnd.getTime()
            );

            if (!payPeriod) {
                // Create pay period
                payPeriod = await payPeriodsService.create(samUser.id, {
                    periodStart,
                    periodEnd,
                    frequency: 'MONTHLY',
                });

                // Create payroll records for each worker
                for (const record of period.records) {
                    const worker = workerMap.get(record.name);
                    if (worker) {
                        await payrollService.create({
                            userId: samUser.id,
                            workerId: worker.id,
                            payPeriodId: payPeriod.id,
                            periodStart,
                            periodEnd,
                            grossSalary: parseFloat(record.gross_salary),
                            bonuses: 0,
                            otherEarnings: 0,
                            otherDeductions: 0,
                            holidayHours: 0,
                            sundayHours: 0,
                            overtimePay: 0,
                            netSalary: 0, // Will be calculated
                            taxAmount: 0, // Will be calculated
                            status: 'draft',
                            paymentStatus: 'pending',
                            paymentMethod: 'cash',
                        });
                    }
                }

                // Calculate and finalize the payroll
                await payPeriodsService.calculatePayroll(payPeriod.id, samUser.id);
                await payPeriodsService.finalizePayPeriod(payPeriod.id, samUser.id);

                console.log(`   ✅ Created and finalized pay period for ${period.month} ${period.year}`);
            } else {
                console.log(`   ⏭️  Pay period already exists for ${period.month} ${period.year}`);
            }
        }

        console.log('\n\n🎉 Sam Olago data import completed successfully!');
        console.log(`   📊 Total workers: ${extractedData.workers.length}`);
        console.log(`   📅 Total pay periods: ${sortedHistory.length}`);

    } catch (error) {
        console.error('\n❌ Error during import:', error.message);
        console.error(error.stack);
    } finally {
        await app.close();
    }
}

importSamOlagoData();
