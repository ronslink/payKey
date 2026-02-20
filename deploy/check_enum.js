const { Client } = require('pg');
const c = new Client(process.env.DATABASE_URL);
c.connect().then(async () => {
    const payPeriodId = '82daa91e-7df4-4f32-96af-112a83a229e1';
    const userId = 'a61cc904-f998-47d8-913a-1b4980c4f194';

    // Check actual enum values
    const enums = await c.query("SELECT enumlabel FROM pg_enum WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'pay_periods_status_enum') ORDER BY enumsortorder");
    console.log('VALID ENUM VALUES:', enums.rows.map(r => r.enumlabel));

    // Check current pay period status
    const pp = await c.query('SELECT id, status, name FROM pay_periods WHERE id = $1', [payPeriodId]);
    console.log('CURRENT PAY PERIOD:', JSON.stringify(pp.rows[0]));

    await c.end();
}).catch(e => { console.error(e); process.exit(1); });
