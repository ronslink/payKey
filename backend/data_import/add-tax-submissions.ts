// @ts-nocheck
// Adds simulated tax submissions for Jan 2024 - Nov 2025
// December 2025 remains unfiled

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';

async function addTaxSubmissions() {
    console.log('📋 Adding simulated tax submissions (Jan 2024 - Nov 2025)...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    try {
        // Get Sam's user
        const users = await ds.query(`SELECT id FROM users WHERE email = 'kingpublish@gmail.com'`);
        const samId = users[0].id;
        console.log('Sam ID:', samId);

        // Get all pay periods except December 2025 and 2026
        const periods = await ds.query(`
            SELECT id, name, "startDate", "endDate"
            FROM pay_periods 
            WHERE "userId" = $1 
            AND (
                EXTRACT(YEAR FROM "startDate") < 2025 
                OR (EXTRACT(YEAR FROM "startDate") = 2025 AND EXTRACT(MONTH FROM "startDate") < 12)
            )
            ORDER BY "startDate"
        `, [samId]);

        console.log(`Found ${periods.length} periods to file taxes for\n`);

        let filedCount = 0;

        for (const period of periods) {
            // Check if tax submission exists
            const existing = await ds.query(`
                SELECT id FROM tax_submissions 
                WHERE "payPeriodId" = $1
            `, [period.id]);

            if (existing.length > 0) {
                console.log(`   ✓ ${period.name} already has submission`);
                continue;
            }

            // Calculate tax amounts from payroll records
            const taxTotals = await ds.query(`
                SELECT 
                    COALESCE(SUM((("taxBreakdown"->>'paye')::numeric)), 0) as paye,
                    COALESCE(SUM((("taxBreakdown"->>'nssf')::numeric)), 0) as nssf,
                    COALESCE(SUM((("taxBreakdown"->>'nhif')::numeric)), 0) as nhif
                FROM payroll_records
                WHERE "payPeriodId" = $1
            `, [period.id]);

            const paye = parseFloat(taxTotals[0].paye) || 0;
            const nssf = parseFloat(taxTotals[0].nssf) || 0;
            const nhif = parseFloat(taxTotals[0].nhif) || 0;
            const housingLevy = 0;

            const submissionId = uuidv4();
            const filingDate = new Date(period.endDate);
            filingDate.setDate(filingDate.getDate() + 5); // Filed 5 days after period end

            // INSERT with correct column names from entity
            await ds.query(`
                INSERT INTO tax_submissions (
                    id, "userId", "payPeriodId",
                    "totalPaye", "totalNssf", "totalNhif", "totalHousingLevy",
                    status, "filingDate",
                    "createdAt", "updatedAt"
                ) VALUES (
                    $1, $2, $3,
                    $4, $5, $6, $7,
                    'FILED', $8,
                    NOW(), NOW()
                )
            `, [
                submissionId, samId, period.id,
                paye, nssf, nhif, housingLevy,
                filingDate
            ]);

            console.log(`   + Filed ${period.name}: PAYE=${paye}, NSSF=${nssf}, SHIF=${nhif}`);
            filedCount++;
        }

        // Verify
        const totalSubmissions = await ds.query(`
            SELECT COUNT(*) as c FROM tax_submissions WHERE "userId" = $1
        `, [samId]);

        console.log(`\n✅ Complete!`);
        console.log(`   Filed: ${filedCount} new submissions`);
        console.log(`   Total: ${totalSubmissions[0].c} submissions`);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

addTaxSubmissions();
