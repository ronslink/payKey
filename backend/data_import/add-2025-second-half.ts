// @ts-nocheck
// Adds simulated payroll for July - December 2025
// Uses same salary/deduction structure as existing data

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';

const MONTHS = [
    { month: 7, name: 'July 2025' },
    { month: 8, name: 'August 2025' },
    { month: 9, name: 'September 2025' },
    { month: 10, name: 'October 2025' },
    { month: 11, name: 'November 2025' },
    { month: 12, name: 'December 2025' },
];

// Worker data based on existing records
const WORKERS = [
    {
        name: 'Kefa, Nicholas Luvaga',  // Updated to mixed case
        gross: 16700.00,
        nssf: 1002.00,
        shif: 500.00,  // SHIF replaces NHIF after Oct 2024
        paye: 0,
        net: 15198.00
    },
    {
        name: 'Musulwa, Janet Ngoyisi',  // Updated to mixed case
        gross: 17800.00,
        nssf: 1068.00,
        shif: 500.00,
        paye: 0,
        net: 16232.00
    }
];

async function addSimulatedData() {
    console.log('📊 Adding simulated July-December 2025 payroll...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    try {
        // Get Sam's user
        const users = await ds.query(`SELECT id FROM users WHERE email = 'kingpublish@gmail.com'`);
        const samId = users[0].id;
        console.log('Sam ID:', samId);

        // Get workers
        const workers = await ds.query(`SELECT id, name FROM workers WHERE "userId" = $1`, [samId]);
        const workerMap = new Map(workers.map(w => [w.name, w.id]));
        console.log('Workers:', Array.from(workerMap.keys()));

        for (const period of MONTHS) {
            const startDate = new Date(2025, period.month - 1, 1);
            const endDate = new Date(2025, period.month, 0); // Last day

            // Check if period exists
            const existing = await ds.query(`
                SELECT id FROM pay_periods 
                WHERE "userId" = $1 AND name = $2
            `, [samId, period.name]);

            let periodId: string;

            if (existing.length > 0) {
                periodId = existing[0].id;
                console.log(`   ✓ ${period.name} exists`);
            } else {
                // Create pay period
                periodId = uuidv4();
                await ds.query(`
                    INSERT INTO pay_periods (id, "userId", name, "startDate", "endDate", "payDate", frequency, status, "isOffCycle", "totalWorkers", "processedWorkers", "createdAt", "updatedAt")
                    VALUES ($1, $2, $3, $4, $5, $5, 'MONTHLY', 'CLOSED', false, 2, 2, NOW(), NOW())
                `, [periodId, samId, period.name, startDate, endDate]);
                console.log(`   + Created ${period.name}`);
            }

            // Create payroll records for each worker
            let totalGross = 0;
            let totalNet = 0;
            let totalTax = 0;

            for (const worker of WORKERS) {
                const workerId = workerMap.get(worker.name);
                if (!workerId) {
                    console.warn(`      ⚠️ Worker not found: ${worker.name}`);
                    continue;
                }

                // Check if record exists
                const existingRecord = await ds.query(`
                    SELECT id FROM payroll_records 
                    WHERE "payPeriodId" = $1 AND "workerId" = $2
                `, [periodId, workerId]);

                if (existingRecord.length > 0) {
                    continue; // Skip if exists
                }

                const recordId = uuidv4();
                const taxBreakdown = {
                    paye: worker.paye,
                    nssf: worker.nssf,
                    nhif: worker.shif,  // Still stored as nhif in taxBreakdown
                    housingLevy: 0,
                    totalDeductions: worker.gross - worker.net
                };

                await ds.query(`
                    INSERT INTO payroll_records (
                        id, "userId", "workerId", "payPeriodId", 
                        "periodStart", "periodEnd",
                        "grossSalary", "netSalary", "taxAmount",
                        status, "paymentStatus", "paymentMethod",
                        "taxBreakdown", deductions,
                        "createdAt", "updatedAt"
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6, $7, $8, $9,
                        'finalized', 'paid', 'cash',
                        $10, $11, NOW(), NOW()
                    )
                `, [
                    recordId, samId, workerId, periodId,
                    startDate, endDate,
                    worker.gross, worker.net, worker.paye,
                    JSON.stringify(taxBreakdown),
                    JSON.stringify({ otherDeductions: 0 })
                ]);

                totalGross += worker.gross;
                totalNet += worker.net;
                totalTax += worker.paye;
            }

            // Update pay period totals
            await ds.query(`
                UPDATE pay_periods 
                SET "totalGrossAmount" = $1, "totalNetAmount" = $2, "totalTaxAmount" = $3
                WHERE id = $4
            `, [totalGross, totalNet, totalTax, periodId]);
        }

        // Verify
        const totalPeriods = await ds.query(`SELECT COUNT(*) as c FROM pay_periods WHERE "userId" = $1`, [samId]);
        const totalRecords = await ds.query(`SELECT COUNT(*) as c FROM payroll_records WHERE "userId" = $1`, [samId]);

        console.log(`\n✅ Complete!`);
        console.log(`   Pay Periods: ${totalPeriods[0].c}`);
        console.log(`   Payroll Records: ${totalRecords[0].c}`);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

addSimulatedData();
