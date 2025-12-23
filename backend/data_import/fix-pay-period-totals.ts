// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function fixAllTotals() {
    console.log('💰 Fixing ALL pay period totals...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    try {
        // Get Sam's user ID
        const users = await ds.query(`SELECT id FROM users WHERE email = 'kingpublish@gmail.com'`);
        const samId = users[0].id;
        console.log('Sam ID:', samId);

        // Get all pay periods
        const periods = await ds.query(`SELECT id, name FROM pay_periods WHERE "userId" = $1`, [samId]);
        console.log(`Found ${periods.length} pay periods\n`);

        for (const period of periods) {
            // Calculate totals from payroll records
            const totals = await ds.query(`
                SELECT 
                    COALESCE(SUM(CAST("grossSalary" AS DECIMAL)), 0) as gross,
                    COALESCE(SUM(CAST("netSalary" AS DECIMAL)), 0) as net,
                    COALESCE(SUM(CAST("taxAmount" AS DECIMAL)), 0) as tax
                FROM payroll_records
                WHERE "payPeriodId" = $1
            `, [period.id]);

            const gross = totals[0].gross;
            const net = totals[0].net;
            const tax = totals[0].tax;

            await ds.query(`
                UPDATE pay_periods 
                SET "totalGrossAmount" = $1, "totalNetAmount" = $2, "totalTaxAmount" = $3
                WHERE id = $4
            `, [gross, net, tax, period.id]);

            console.log(`   ${period.name}: Gross=${gross}, Net=${net}, Tax=${tax}`);
        }

        console.log('\n✅ All pay period totals updated!');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

fixAllTotals();
