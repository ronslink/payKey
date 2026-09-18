'use strict';

// Runs over stdin in the existing container. No Nest bootstrap, migrations,
// provider writes or customer records are read. Never print environment values.
const fs = require('node:fs');
const { Client } = require('/app/node_modules/pg');

async function inspect() {
  const e = process.env;
  const u = new URL(e.DATABASE_URL);
  const candidates = [e.DB_SSL_CA_PATH, '/app/ca-certificate.crt', '/app/certs/ca-certificate.crt'].filter(Boolean);
  const caPath = candidates.find((p) => fs.existsSync(p));
  const report = {
    source: 'running backend',
    release: e.RELEASE_COMMIT || 'unknown',
    database: { host: u.hostname, port: u.port || '5432', name: decodeURIComponent(u.pathname.slice(1)) },
    configuration: {
      nodeEnv: e.NODE_ENV,
      databaseCaPresent: !!caPath,
      redisPasswordPresent: !!e.REDIS_PASSWORD,
      jwtMinimumLength: (e.JWT_SECRET || '').length >= 32,
      stripeLiveKey: /^(sk|rk)_live_/.test(e.STRIPE_SECRET_KEY || ''),
      stripeWebhookPresent: (e.STRIPE_WEBHOOK_SECRET || '').startsWith('whsec_'),
      intasendKeysPresent: !!e.INTASEND_PUBLISHABLE_KEY && !!e.INTASEND_SECRET_KEY,
      intasendLive: e.INTASEND_IS_LIVE === 'true',
      paymentSimulation: e.INTASEND_SIMULATE === 'true',
      signatureBypass: e.INTASEND_DISABLE_SIG_CHECK === 'true',
      emailProvider: e.EMAIL_PROVIDER || 'MOCK',
      smsProvider: e.SMS_PROVIDER || 'MOCK',
    },
  };
  const client = new Client({
    host: u.hostname, port: Number(u.port || 5432), database: decodeURIComponent(u.pathname.slice(1)),
    user: decodeURIComponent(u.username), password: decodeURIComponent(u.password),
    ssl: { rejectUnauthorized: true, ...(caPath ? { ca: fs.readFileSync(caPath, 'utf8') } : {}) },
    connectionTimeoutMillis: 5000, query_timeout: 5000,
    application_name: 'paykey-release-read-only-inspection',
    options: '-c default_transaction_read_only=on -c statement_timeout=5000',
  });
  try {
    await client.connect();
    await client.query('BEGIN READ ONLY');
    report.session = (await client.query("SELECT current_database() AS database, current_setting('transaction_read_only') AS read_only, inet_server_addr()::text AS server_address")).rows[0];
    report.tls = (await client.query('SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()')).rows[0];
    const ledger = (await client.query("SELECT to_regclass('public.migrations') AS name")).rows[0].name;
    report.migrations = ledger ? (await client.query('SELECT name FROM public.migrations ORDER BY id')).rows.map((r) => r.name) : [];
    report.migrationLedgerPresent = !!ledger;
    report.schema = (await client.query("SELECT table_name, column_name FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('tax_payments','subscription_payments','support_tickets','subscriptions') ORDER BY table_name, ordinal_position")).rows;
    await client.query('ROLLBACK');
  } catch (error) {
    report.databaseInspectionFailed = true;
    report.errorCode = /^[A-Z0-9_]+$/.test(error.code || '') ? error.code : 'READ_ONLY_CONNECTION_FAILED';
    process.exitCode = 1;
  } finally {
    await client.end().catch(() => {});
    console.log(JSON.stringify(report, null, 2));
  }
}
inspect().catch(() => { console.error('Production inspection failed without exposing credential values'); process.exitCode = 1; });
