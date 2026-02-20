const { Client } = require('pg');
const c = new Client(process.env.DATABASE_URL);
c.connect().then(async () => {
    const payPeriodId = '82daa91e-7df4-4f32-96af-112a83a229e1';
    const userId = 'a61cc904-f998-47d8-913a-1b4980c4f194';

    // 1. Reset pay period from PROCESSING to ACTIVE
    const r1 = await c.query(
        `UPDATE pay_periods SET status = 'ACTIVE' WHERE id = $1 RETURNING id, status, name`,
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
    console.log('CURRENT RECORDS:', JSON.stringify(r3.rows, null, 2));

    const u = await c.query('SELECT "walletBalance" FROM users WHERE id = $1', [userId]);
    console.log('WALLET BALANCE:', u.rows[0].walletBalance);

    await c.end();
    console.log('DONE - Payroll fully reset');
}).catch(e => { console.error(e); process.exit(1); });
