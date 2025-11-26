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
const typeorm_1 = require("typeorm");
const worker_entity_1 = require("./modules/workers/entities/worker.entity");
const pay_period_entity_1 = require("./modules/payroll/entities/pay-period.entity");
const payroll_record_entity_1 = require("./modules/payroll/entities/payroll-record.entity");
const user_entity_1 = require("./modules/users/entities/user.entity");
const bcrypt = __importStar(require("bcrypt"));
const worker_entity_2 = require("./modules/workers/entities/worker.entity");
async function seedDemoData() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const dataSource = app.get(typeorm_1.DataSource);
    try {
        console.log('Cleaning existing demo data...');
        await dataSource.getRepository(payroll_record_entity_1.PayrollRecord).delete({});
        await dataSource.getRepository(pay_period_entity_1.PayPeriod).delete({});
        await dataSource.getRepository(worker_entity_1.Worker).delete({});
        await dataSource
            .getRepository(user_entity_1.User)
            .delete({ email: 'testuser@paykey.com' });
        console.log('Creating demo user...');
        const userRepository = dataSource.getRepository(user_entity_1.User);
        const workerRepository = dataSource.getRepository(worker_entity_1.Worker);
        const payPeriodRepository = dataSource.getRepository(pay_period_entity_1.PayPeriod);
        const payrollRecordRepository = dataSource.getRepository(payroll_record_entity_1.PayrollRecord);
        const demoUser = userRepository.create({
            email: 'testuser@paykey.com',
            firstName: 'Test',
            lastName: 'User',
            passwordHash: await bcrypt.hash('password123', 10),
        });
        await userRepository.save(demoUser);
        console.log('Creating demo workers...');
        const demoWorkers = [
            {
                name: 'John Kamau Mwangi',
                email: 'john.kamau@company.com',
                phoneNumber: '+254701234567',
                idNumber: '12345678',
                kraPin: 'A123456789B',
                nssfNumber: 'NSSF123456',
                nhifNumber: 'NHIF789012',
                jobTitle: 'Software Developer',
                salaryGross: 120000,
                hourlyRate: 692.31,
                employmentType: worker_entity_2.EmploymentType.FIXED,
                paymentFrequency: worker_entity_2.PaymentFrequency.MONTHLY,
                startDate: new Date('2023-01-15'),
                isActive: true,
                housingAllowance: 25000,
                transportAllowance: 15000,
                mpesaNumber: '+254701234567',
                user: demoUser,
                userId: demoUser.id,
            },
            {
                name: 'Sarah Wanjiku Njeri',
                email: 'sarah.wanjiku@company.com',
                phoneNumber: '+254702345678',
                idNumber: '23456789',
                kraPin: 'B987654321C',
                nssfNumber: 'NSSF234567',
                nhifNumber: 'NHIF890123',
                jobTitle: 'Marketing Manager',
                salaryGross: 85000,
                hourlyRate: 489.66,
                employmentType: worker_entity_2.EmploymentType.FIXED,
                paymentFrequency: worker_entity_2.PaymentFrequency.MONTHLY,
                startDate: new Date('2022-08-01'),
                isActive: true,
                housingAllowance: 18000,
                transportAllowance: 12000,
                mpesaNumber: '+254702345678',
                user: demoUser,
                userId: demoUser.id,
            },
            {
                name: 'Michael Ochieng Otieno',
                email: 'michael.ochieng@company.com',
                phoneNumber: '+254703456789',
                idNumber: '34567890',
                kraPin: 'C876543210D',
                nssfNumber: 'NSSF345678',
                nhifNumber: 'NHIF901234',
                jobTitle: 'Construction Worker',
                salaryGross: 0,
                hourlyRate: 500,
                employmentType: worker_entity_2.EmploymentType.HOURLY,
                paymentFrequency: worker_entity_2.PaymentFrequency.WEEKLY,
                startDate: new Date('2023-06-01'),
                isActive: true,
                mpesaNumber: '+254703456789',
                user: demoUser,
                userId: demoUser.id,
            },
            {
                name: 'Grace Achieng Adhiambo',
                email: 'grace.achieng@company.com',
                phoneNumber: '+254704567890',
                idNumber: '45678901',
                kraPin: 'D765432109E',
                nssfNumber: 'NSSF456789',
                nhifNumber: 'NHIF012345',
                jobTitle: 'HR Specialist',
                salaryGross: 65000,
                hourlyRate: 374.14,
                employmentType: worker_entity_2.EmploymentType.FIXED,
                paymentFrequency: worker_entity_2.PaymentFrequency.MONTHLY,
                startDate: new Date('2023-03-01'),
                isActive: true,
                housingAllowance: 15000,
                transportAllowance: 10000,
                mpesaNumber: '+254704567890',
                user: demoUser,
                userId: demoUser.id,
            },
            {
                name: 'David Kiprotich Chepkemoi',
                email: 'david.kiprotich@company.com',
                phoneNumber: '+254705678901',
                idNumber: '56789012',
                kraPin: 'E654321098F',
                nssfNumber: 'NSSF567890',
                nhifNumber: 'NHIF123456',
                jobTitle: 'Accountant',
                salaryGross: 95000,
                hourlyRate: 546.51,
                employmentType: worker_entity_2.EmploymentType.FIXED,
                paymentFrequency: worker_entity_2.PaymentFrequency.MONTHLY,
                startDate: new Date('2022-11-01'),
                isActive: true,
                housingAllowance: 20000,
                transportAllowance: 14000,
                mpesaNumber: '+254705678901',
                user: demoUser,
                userId: demoUser.id,
            },
        ];
        const savedWorkers = await workerRepository.save(demoWorkers);
        console.log(`Created ${savedWorkers.length} demo workers`);
        console.log('Creating pay periods for the last 3 months...');
        const currentDate = new Date();
        const threeMonthsAgo = new Date();
        threeMonthsAgo.setMonth(currentDate.getMonth() - 3);
        const payPeriods = [];
        const periodStart = new Date(threeMonthsAgo);
        const currentPeriodStart = new Date(periodStart);
        while (currentPeriodStart <= currentDate) {
            const periodEnd = new Date(currentPeriodStart);
            periodEnd.setDate(periodEnd.getDate() + 13);
            if (periodEnd > currentDate)
                break;
            const payDate = new Date(periodEnd);
            payDate.setDate(payDate.getDate() + 3);
            const periodName = `${currentPeriodStart.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })} - Week ${Math.ceil(currentPeriodStart.getDate() / 14)}`;
            payPeriods.push({
                name: periodName,
                startDate: currentPeriodStart,
                endDate: periodEnd,
                payDate: payDate.toISOString().split('T')[0],
                frequency: pay_period_entity_1.PayPeriodFrequency.BIWEEKLY,
                status: pay_period_entity_1.PayPeriodStatus.COMPLETED,
                createdBy: demoUser.id,
                processedAt: new Date(periodEnd.getTime() + 24 * 60 * 60 * 1000),
            });
            currentPeriodStart.setDate(currentPeriodStart.getDate() + 14);
        }
        const savedPayPeriods = await payPeriodRepository.save(payPeriods);
        console.log(`Created ${savedPayPeriods.length} pay periods`);
        console.log('Creating payroll records with varied scenarios...');
        const payrollRecords = [];
        for (const payPeriod of savedPayPeriods) {
            for (const worker of savedWorkers) {
                let grossSalary = 0;
                if (worker.employmentType === worker_entity_2.EmploymentType.FIXED) {
                    const monthlySalary = worker.salaryGross;
                    switch (payPeriod.frequency) {
                        case pay_period_entity_1.PayPeriodFrequency.BIWEEKLY:
                            grossSalary = monthlySalary / 2;
                            break;
                        case pay_period_entity_1.PayPeriodFrequency.MONTHLY:
                            grossSalary = monthlySalary;
                            break;
                        case pay_period_entity_1.PayPeriodFrequency.WEEKLY:
                            grossSalary = monthlySalary / 4;
                            break;
                    }
                    const housingAllowance = Number(worker.housingAllowance) || 0;
                    const transportAllowance = Number(worker.transportAllowance) || 0;
                    grossSalary += housingAllowance + transportAllowance;
                    if (Math.random() < 0.2) {
                        grossSalary *= 1.2;
                    }
                }
                else {
                    const hoursWorked = 80 + Math.floor(Math.random() * 40);
                    grossSalary = Number(worker.hourlyRate) * hoursWorked;
                    const overtimeHours = Math.max(0, hoursWorked - 80);
                    if (overtimeHours > 0) {
                        grossSalary += overtimeHours * Number(worker.hourlyRate) * 1.5;
                    }
                }
                const taxAmount = calculateTax(grossSalary);
                const netSalary = grossSalary - taxAmount;
                let paymentStatus = 'paid';
                const random = Math.random();
                if (random < 0.1)
                    paymentStatus = 'pending';
                else if (random < 0.05)
                    paymentStatus = 'processing';
                payrollRecords.push({
                    userId: demoUser.id,
                    workerId: worker.id,
                    periodStart: payPeriod.startDate,
                    periodEnd: payPeriod.endDate,
                    grossSalary: Math.round(grossSalary * 100) / 100,
                    netSalary: Math.round(netSalary * 100) / 100,
                    taxAmount: Math.round(taxAmount * 100) / 100,
                    paymentStatus,
                    paymentMethod: 'mpesa',
                    paymentDate: paymentStatus === 'paid' ? new Date(payPeriod.payDate) : undefined,
                    taxBreakdown: {
                        incomeTax: taxAmount,
                        nhif: Math.min(grossSalary * 0.015, 300),
                        nssf: Math.min(grossSalary * 0.06, 200),
                        grossSalary,
                        netSalary,
                    },
                    deductions: {
                        loanDeduction: Math.random() < 0.1
                            ? Math.round(grossSalary * 0.1 * 100) / 100
                            : 0,
                        insurance: Math.round(grossSalary * 0.02 * 100) / 100,
                    },
                });
            }
        }
        const savedPayrollRecords = await payrollRecordRepository.save(payrollRecords);
        console.log(`Created ${savedPayrollRecords.length} payroll records`);
        console.log('Updating pay period totals...');
        for (const payPeriod of savedPayPeriods) {
            const periodRecords = savedPayrollRecords.filter((r) => r.periodStart.getTime() === payPeriod.startDate.getTime() &&
                r.periodEnd.getTime() === payPeriod.endDate.getTime());
            const totals = periodRecords.reduce((acc, record) => ({
                grossAmount: acc.grossAmount + Number(record.grossSalary),
                netAmount: acc.netAmount + Number(record.netSalary),
                taxAmount: acc.taxAmount + Number(record.taxAmount),
                processedWorkers: acc.processedWorkers + 1,
            }), { grossAmount: 0, netAmount: 0, taxAmount: 0, processedWorkers: 0 });
            await payPeriodRepository.update(payPeriod.id, {
                totalGrossAmount: totals.grossAmount,
                totalNetAmount: totals.netAmount,
                totalTaxAmount: totals.taxAmount,
                totalWorkers: periodRecords.length,
                processedWorkers: totals.processedWorkers,
            });
        }
        console.log('\n=== Demo Data Summary ===');
        console.log(`✅ Demo User: ${demoUser.email}`);
        console.log(`✅ Created ${savedWorkers.length} workers`);
        console.log(`✅ Created ${savedPayPeriods.length} pay periods`);
        console.log(`✅ Created ${savedPayrollRecords.length} payroll records`);
        console.log('\nLogin with: testuser@paykey.com / password123');
    }
    catch (error) {
        console.error('Error seeding demo data:', error);
    }
    finally {
        await app.close();
    }
}
function calculateTax(grossSalary) {
    let tax = 0;
    if (grossSalary > 1000000 / 12) {
        tax += (grossSalary - 83333) * 0.25;
        grossSalary = 83333;
    }
    if (grossSalary > 500000 / 12) {
        tax += (grossSalary - 41667) * 0.2;
        grossSalary = 41667;
    }
    if (grossSalary > 240000 / 12) {
        tax += (grossSalary - 20000) * 0.15;
        grossSalary = 20000;
    }
    if (grossSalary > 120000 / 12) {
        tax += (grossSalary - 10000) * 0.1;
    }
    tax = Math.max(0, tax - 2400 / 12);
    return Math.round(tax * 100) / 100;
}
seedDemoData().catch(console.error);
//# sourceMappingURL=seed-pay-periods-demo-data.js.map