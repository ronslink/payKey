const { Client } = require('pg');
const c = new Client(process.env.DATABASE_URL);
c.connect().then(async () => {
    const payPeriodId = '82daa91e-7df4-4f32-96af-112a83a229e1';
    const userId = 'a61cc904-f998-47d8-913a-1b4980c4f194';

    // 1. Reset pay period to 'active' so user can re-run payroll
    const r1 = await c.query(
        `UPDATE pay_periods SET status = 'active' WHERE id = $1 RETURNING id, status, name`,
        [payPeriodId]
    );
    console.log('RESET PAY PERIOD:', JSON.stringify(r1.rows[0]));

    // 2. Clean up failed transaction records
    const r2 = await c.query(
        `DELETE FROM transactions WHERE "userId" = $1 AND status = 'FAILED' AND type = 'SALARY_PAYOUT'`,
        [userId]
    );
    console.log('CLEANED UP FAILED TRANSACTIONS:', r2.rowCount);

    // 3. Verify final state
    const r3 = await c.query(
        `SELECT pr.id, pr.status, pr."paymentStatus", pr."netSalary", w.name 
     FROM payroll_records pr JOIN workers w ON w.id = pr."workerId" 
     WHERE pr."userId" = $1 AND pr."payPeriodId" = $2`,
        [userId, payPeriodId]
    );
    console.log('CURRENT RECORDS FOR THIS PERIOD:', JSON.stringify(r3.rows, null, 2));

    await c.end();
    console.log('DONE');
}).catch(e => { console.error(e); process.exit(1); });
