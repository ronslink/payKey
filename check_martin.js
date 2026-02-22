const { Client } = require("pg");
const c = new Client({ connectionString: process.env.DATABASE_URL });
c.connect()
  .then(async () => {
    const r = await c.query("SELECT u.id, u.email, u.tier, s.status, s.tier, s.\"currentPeriodStart\", s.\"currentPeriodEnd\" FROM users u LEFT JOIN subscriptions s ON s.\"userId\" = u.id WHERE u.email = 'martin.s@gmail.com'");
    console.log(JSON.stringify(r.rows, null, 2));
    await c.end();
  })
  .catch(e => console.error(e));
