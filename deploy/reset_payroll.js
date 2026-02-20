const { Client } = require('pg');
const c = new Client(process.env.DATABASE_URL);
c.connect().then(async () => {
    const recordId = '7df4c0a5-09ca-4d33-aa96-95502afc43dc';
    const payPeriodId = '82daa91e-7df4-4f32-96af-112a83a229e1';

    // 1. Reset Tamara's payroll record to draft
    const r1 = await c.query(
        `UPDATE payroll_records SET status = 'draft', "paymentStatus" = 'pending' WHERE id = $1 RETURNING id, status, "paymentStatus", "netSalary"`,
        [recordId]
    );
    console.log('RESET PAYROLL RECORD:', JSON.stringify(r1.rows[0]));

    // 2. Reset the pay period status back to OPEN so user can re-run
    const r2 = await c.query(
        `UPDATE pay_periods SET status = 'open' WHERE id = $1 RETURNING id, status, name`,
        [payPeriodId]
    );
    console.log('RESET PAY PERIOD:', JSON.stringify(r2.rows[0]));

    // 3. Clean up the failed transaction records
    const r3 = await c.query(
        `DELETE FROM transactions WHERE "userId" = 'a61cc904-f998-47d8-913a-1b4980c4f194' AND status = 'FAILED' AND type = 'SALARY_PAYOUT'`
    );
    console.log('CLEANED UP FAILED TRANSACTIONS:', r3.rowCount);

    await c.end();
    console.log('DONE - Payroll reset successfully');
}).catch(e => { console.error(e); process.exit(1); });
