const { Client } = require('pg');
const c = new Client(process.env.DATABASE_URL);
c.connect().then(async () => {
    const uid = 'a61cc904-f998-47d8-913a-1b4980c4f194';

    const r = await c.query(
        `SELECT pr.id, pr.status, pr."paymentStatus", pr."netSalary", pr."grossSalary", w.name as worker_name
     FROM payroll_records pr JOIN workers w ON w.id = pr."workerId"
     WHERE pr."userId" = $1 ORDER BY pr."updatedAt" DESC LIMIT 5`, [uid]
    );
    console.log('PAYROLL RECORDS:');
    console.log(JSON.stringify(r.rows, null, 2));

    const u = await c.query(
        `SELECT "walletBalance", "clearingBalance", email FROM users WHERE id = $1`, [uid]
    );
    console.log('WALLET:', JSON.stringify(u.rows[0]));

    const t = await c.query(
        `SELECT id, amount, status, type, "createdAt" FROM transactions WHERE "userId" = $1 ORDER BY "createdAt" DESC LIMIT 5`, [uid]
    );
    console.log('RECENT TRANSACTIONS:');
    console.log(JSON.stringify(t.rows, null, 2));

    await c.end();
}).catch(e => { console.error(e); process.exit(1); });
