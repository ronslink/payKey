// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/modules/auth/auth.service';
import { UsersService } from '../src/modules/users/users.service';
import { Worker, EmploymentType, PaymentFrequency, PaymentMethod } from '../src/modules/workers/entities/worker.entity';
import { Property } from '../src/modules/properties/entities/property.entity';
import { PayPeriod, PayPeriodStatus, PayPeriodFrequency } from '../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord, PayrollStatus } from '../src/modules/payroll/entities/payroll-record.entity';
import { User, UserRole } from '../src/modules/users/entities/user.entity';
import { Subscription, SubscriptionStatus, SubscriptionTier } from '../src/modules/subscriptions/entities/subscription.entity';
import { SubscriptionPayment, PaymentStatus, PaymentMethod as SubPaymentMethod } from '../src/modules/subscriptions/entities/subscription-payment.entity';
import { DataSource, Repository } from 'typeorm';
import * as fs from 'fs';
import * as path from 'path';

// Load extracted data
const extractedDataPath = path.join(__dirname, 'extracted_data.json');
const extractedData = JSON.parse(fs.readFileSync(extractedDataPath, 'utf-8'));

async function importSamOlagoData() {
    console.log('🚀 Starting Sam Olago data import (DIRECT REPOSITORY MODE)...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const authService = app.get(AuthService);
    const usersService = app.get(UsersService);

    // Repositories
    const workerRepo = dataSource.getRepository(Worker);
    const propertyRepo = dataSource.getRepository(Property);
    const payPeriodRepo = dataSource.getRepository(PayPeriod);
    const payrollRepo = dataSource.getRepository(PayrollRecord);
    const subscriptionRepo = dataSource.getRepository(Subscription);
    const subPaymentRepo = dataSource.getRepository(SubscriptionPayment);

    try {
        // =====================================================================
        // Step 1: User & Auth
        // =====================================================================
        console.log('👤 Step 1: Ensure User Exists...');
        let samUser: User | null = await usersService.findOneByEmail('kingpublish@gmail.com');

        if (!samUser) {
            console.log('   Creating new user...');
            await authService.register({
                email: 'kingpublish@gmail.com',
                password: 'Sam2026test!',
                name: 'Sam Olago',
            });
            samUser = await usersService.findOneByEmail('kingpublish@gmail.com');
            console.log('   ✅ User created');
        } else {
            console.log('   ✅ User found');
        }

        if (!samUser) {
            throw new Error('Failed to create or find user');
        }

        // Complete onboarding and user profile if not done
        if (!samUser.isOnboardingCompleted) {
            console.log('   Completing onboarding and user profile...');
            const countries = await dataSource.query(`SELECT id FROM countries WHERE code = 'KE' LIMIT 1`);
            const kenyaId = countries.length > 0 ? countries[0].id : null;

            await dataSource.query(`
                UPDATE users SET 
                    "firstName" = 'Samuel', 
                    "lastName" = 'Olago',
                    "businessName" = 'Samuel Olago Household',
                    "idType" = 'NATIONAL_ID', 
                    "idNumber" = '12345678',
                    "nationalityId" = $1, 
                    "countryId" = $1,
                    "kraPin" = 'A001234567X',
                    "nssfNumber" = 'NSSF123456',
                    "shifNumber" = 'SHIF789012',
                    "address" = 'P.O. Box 67578 Nairobi 00200 Kenya',
                    "city" = 'Nairobi',
                    "phoneNumber" = '+254712492207',
                    "residentStatus" = 'RESIDENT',
                    "isOnboardingCompleted" = true,
                    tier = 'PLATINUM'
                WHERE id = $2
            `, [kenyaId, samUser.id]);
            console.log('   ✅ User profile and onboarding completed');
        }

        // =====================================================================
        // Step 2: Subscription (Platinum)
        // =====================================================================
        console.log('\n💎 Step 2: Setup Platinum Subscription...');
        let subscription = await subscriptionRepo.findOne({
            where: { userId: samUser.id, status: SubscriptionStatus.ACTIVE }
        });

        if (!subscription) {
            subscription = subscriptionRepo.create({
                userId: samUser.id,
                tier: SubscriptionTier.PLATINUM,
                status: SubscriptionStatus.ACTIVE,
                startDate: new Date('2024-01-01'),
                nextBillingDate: new Date('2025-12-31'), // Valid for a year
                amount: 49.99, // Dummy amount
                currency: 'USD'
            });
            await subscriptionRepo.save(subscription);
            console.log('   ✅ Created Platinum Subscription');
        } else {
            console.log('   ℹ️ Subscription already exists, updating to Platinum...');
            subscription.tier = SubscriptionTier.PLATINUM;
            await subscriptionRepo.save(subscription);
        }

        // Ensure a "Paid" payment record exists so system sees it as good standing
        const existingPayment = await subPaymentRepo.findOne({ where: { subscriptionId: subscription.id } });
        if (!existingPayment) {
            await subPaymentRepo.save(subPaymentRepo.create({
                subscriptionId: subscription.id,
                userId: samUser.id,
                amount: 49.99,
                status: PaymentStatus.COMPLETED,
                paymentMethod: SubPaymentMethod.CREDIT_CARD,
                billingPeriod: 'Yearly 2025',
                periodStart: new Date(),
                periodEnd: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
                dueDate: new Date(),
                paidDate: new Date()
            }));
            console.log('   ✅ Recorded Subscription Payment');
        }

        // =====================================================================
        // Step 3: Property
        // =====================================================================
        console.log('\n🏢 Step 3: Setup Property...');
        const propertyName = 'Samuel Olago - UNON';
        let property = await propertyRepo.findOne({
            where: { userId: samUser.id, name: propertyName }
        });

        if (!property) {
            property = propertyRepo.create({
                userId: samUser.id,
                name: propertyName,
            });
        }

        // Update details (whether new or existing)
        property.address = 'House 26, Stream Drive Thome 1 Estate';
        property.latitude = -1.223039;
        property.longitude = 36.870959;
        property.what3words = '///rise.condition.hype';
        property.isActive = true;

        property = await propertyRepo.save(property);
        console.log(`   ✅ Property confirmed: ${property.name} (${property.what3words})`);


        // =====================================================================
        // Step 4: Workers
        // =====================================================================
        console.log('\n👷 Step 4: Import Workers...');
        const workerMap = new Map<string, Worker>();

        let phoneCounter = 1;

        for (const workerData of extractedData.workers) {
            // Try identify by KRA PIN or Name
            let worker = await workerRepo.findOne({
                where: [
                    { kraPin: workerData.pin, userId: samUser.id },
                    { name: workerData.name, userId: samUser.id }
                ]
            });

            if (!worker) {
                worker = new Worker();
                worker.userId = samUser.id;
                worker.createdAt = new Date('2024-01-01');
                console.log(`   ✨ Creating new worker: ${workerData.name}`);
            } else {
                console.log(`   🔄 Updating existing worker: ${workerData.name}`);
            }

            // Populate/Update fields
            worker.name = workerData.name;
            worker.propertyId = property.id;

            // Enrich missing data
            if (!worker.phoneNumber) {
                worker.phoneNumber = `+2547${String(phoneCounter).padStart(8, '0')}`; // +254700000001 etc
                phoneCounter++;
            }

            worker.idNumber = workerData.id_no || `GEN-ID-${workerData.emp_no}`;
            worker.kraPin = workerData.pin;
            worker.nssfNumber = workerData.nssf;
            worker.nhifNumber = workerData.nhif;
            worker.jobTitle = workerData.job_title;

            // CRITICAL: Set salary to most recent value (assuming JSON array represents latest state)
            worker.salaryGross = parseFloat(workerData.basic_pay.replace(/,/g, ''));

            worker.employmentType = EmploymentType.FIXED;
            worker.paymentFrequency = PaymentFrequency.MONTHLY;
            worker.paymentMethod = PaymentMethod.CASH; // Default to Cash for now
            worker.startDate = new Date('2024-01-01');
            worker.leaveBalance = 21; // Kenya statutory annual leave

            // Generate random DOB if not set (adults 25-55 years old)
            if (!worker.dateOfBirth) {
                const randomYear = 1970 + Math.floor(Math.random() * 25); // 1970-1995
                const randomMonth = Math.floor(Math.random() * 12) + 1;
                const randomDay = Math.floor(Math.random() * 28) + 1;
                worker.dateOfBirth = new Date(randomYear, randomMonth - 1, randomDay);
            }

            // Save
            worker = await workerRepo.save(worker);
            workerMap.set(worker.name, worker);
        }

        // =====================================================================
        // Step 5: Historical Payroll
        // =====================================================================
        console.log('\n📚 Step 5: Import Historical Payroll...');
        const monthOrder: Record<string, number> = {
            'January': 0, 'February': 1, 'March': 2, 'April': 3,
            'May': 4, 'June': 5, 'July': 6, 'August': 7,
            'September': 8, 'October': 9, 'November': 10, 'December': 11
        };

        const sortedHistory = extractedData.payroll_history.sort((a, b) => {
            const yA = parseInt(a.year);
            const yB = parseInt(b.year);
            if (yA !== yB) return yA - yB;
            return monthOrder[a.month] - monthOrder[b.month];
        });

        for (const periodData of sortedHistory) {
            const year = parseInt(periodData.year);
            const monthIndex = monthOrder[periodData.month];

            const startDate = new Date(year, monthIndex, 1);
            const endDate = new Date(year, monthIndex + 1, 0); // Last day of month

            console.log(`   📅 Processing ${periodData.month} ${year}...`);

            // 1. Create/Get PayPeriod
            let payPeriod = await payPeriodRepo.findOne({
                where: {
                    userId: samUser.id,
                    startDate: startDate
                }
            });

            if (!payPeriod) {
                payPeriod = payPeriodRepo.create({
                    userId: samUser.id,
                    name: `${periodData.month} ${year}`,
                    startDate: startDate,
                    endDate: endDate,
                    payDate: endDate,
                    frequency: PayPeriodFrequency.MONTHLY,
                    status: PayPeriodStatus.CLOSED, // IMPORTANT: Historical periods are closed
                    isOffCycle: false,
                    totalWorkers: periodData.records.length,
                    processedWorkers: periodData.records.length
                });
                payPeriod = await payPeriodRepo.save(payPeriod);
            }

            // 2. Create Payroll Records
            for (const recordData of periodData.records) {
                const worker = workerMap.get(recordData.name);
                if (!worker) {
                    console.warn(`      ⚠️ Skipping record for unknown worker: ${recordData.name}`);
                    continue;
                }

                const gross = parseFloat(recordData.gross_salary?.replace(/,/g, '') || '0');
                const net = parseFloat(recordData.net_pay?.replace(/,/g, '') || '0');
                const paye = parseFloat(recordData.paye?.replace(/,/g, '') || '0');
                const nssf = parseFloat(recordData.nssf_employee?.replace(/,/g, '') || '0');
                const nhif = parseFloat(recordData.nhif?.replace(/,/g, '') || '0');
                const housingLevy = 0; // Not explicitly in some records, assume 0 if missing

                // Check if record exists
                let record = await payrollRepo.findOne({
                    where: { payPeriodId: payPeriod.id, workerId: worker.id }
                });

                if (!record) {
                    record = payrollRepo.create({
                        userId: samUser.id,
                        payPeriodId: payPeriod.id,
                        workerId: worker.id,
                        periodStart: startDate,
                        periodEnd: endDate,
                        status: PayrollStatus.FINALIZED, // IMPORTANT: Finalized
                        paymentStatus: 'paid', // IMPORTANT: Paid
                        paymentMethod: 'cash', // Force Cash for history

                        grossSalary: gross,
                        netSalary: net,
                        taxAmount: paye,

                        // Breakdown
                        taxBreakdown: {
                            paye: paye,
                            nssf: nssf,
                            nhif: nhif,
                            housingLevy: housingLevy,
                            totalDeductions: gross - net
                        },
                        deductions: {
                            otherDeductions: 0
                        }
                    });

                    await payrollRepo.save(record);
                }
            }

            // 3. Calculate and update pay period totals
            const periodTotals = await dataSource.query(`
                SELECT 
                    COALESCE(SUM(CAST("grossSalary" AS DECIMAL)), 0) as gross,
                    COALESCE(SUM(CAST("netSalary" AS DECIMAL)), 0) as net,
                    COALESCE(SUM(CAST("taxAmount" AS DECIMAL)), 0) as tax
                FROM payroll_records
                WHERE "payPeriodId" = $1
            `, [payPeriod.id]);

            await dataSource.query(`
                UPDATE pay_periods 
                SET "totalGrossAmount" = $1, "totalNetAmount" = $2, "totalTaxAmount" = $3
                WHERE id = $4
            `, [periodTotals[0].gross, periodTotals[0].net, periodTotals[0].tax, payPeriod.id]);
        }

        console.log('\n✅ Import Completed Successfully!');

    } catch (error) {
        console.error('\n❌ Error during import:', error);
    } finally {
        await app.close();
    }
}

importSamOlagoData();
