#!/usr/bin/env node
'use strict';

// Read-only by construction: do not import AppModule, ormconfig, services,
// migrations or anything that might initialize Nest/TypeORM or seed data.
const fs = require('node:fs');
const path = require('node:path');
const { Client } = require('pg');
const {
  getDatabaseConnection,
} = require('../dist/src/config/database-connection.js');

// TypeORM identifies an applied migration by its instance name (or constructor
// name), not its filename or timestamp. Several legacy migrations share a
// timestamp and do not use timestamp-prefixed filenames. Read their compiled
// declarations without importing modules: an audit must never run migration
// module initialization, constructors or SQL.
function readMigrationIdentities(directory) {
  return fs.readdirSync(directory).filter((file) => file.endsWith('.js')).map((file) => {
    const source = fs.readFileSync(path.join(directory, file), 'utf8');
    const exportedClasses = [...source.matchAll(/\bclass\s+([A-Za-z_$][\w$]*)\s*\{/g)]
      .map((match) => match[1])
      .filter((name) => new RegExp(`exports\\.${name.replace(/\$/g, '\\$')}\\s*=\\s*${name.replace(/\$/g, '\\$')}\\s*;`).test(source));
    if (exportedClasses.length !== 1)
      throw new Error('Deployed image contains an unsupported migration declaration');
    const declaredName = source.match(/^\s*(?:this\.)?name\s*=\s*(['"])([^'"\r\n]+)\1\s*;?\s*$/m);
    if (/^\s*(?:this\.)?name\s*=/m.test(source) && !declaredName)
      throw new Error('Deployed image contains an unsupported migration name');
    const name = declaredName ? declaredName[2] : exportedClasses[0];
    if (!/^[A-Za-z_$][\w$]*\d{13}$/.test(name))
      throw new Error('Deployed image contains an invalid migration name');
    return { file, name };
  });
}

async function audit() {
  const get = (name) => process.env[name];
  const connection = getDatabaseConnection(get);
  if (get('NODE_ENV') !== 'production')
    throw new Error('Production audit requires NODE_ENV=production');
  const required = [
    'JWT_SECRET',
    'REDIS_PASSWORD',
    'INTASEND_PUBLISHABLE_KEY',
    'INTASEND_SECRET_KEY',
    'STRIPE_SECRET_KEY',
    'STRIPE_WEBHOOK_SECRET',
  ];
  const missing = required.filter((name) => !get(name)?.trim());
  if (
    !get('INTASEND_CHALLENGE')?.trim() &&
    !get('INTASEND_WEBHOOK_SECRET')?.trim()
  )
    missing.push('INTASEND_CHALLENGE or INTASEND_WEBHOOK_SECRET');
  if (missing.length)
    throw new Error(`Missing required configuration: ${missing.join(', ')}`);
  if (
    !/^(sk|rk)_live_/.test(get('STRIPE_SECRET_KEY')) ||
    !get('STRIPE_WEBHOOK_SECRET').startsWith('whsec_')
  )
    throw new Error(
      'Missing required configuration: live Stripe API key and webhook signing secret',
    );
  if (get('JWT_SECRET').length < 32 || get('REDIS_PASSWORD').length < 16)
    throw new Error(
      'JWT_SECRET or REDIS_PASSWORD does not meet minimum length',
    );
  if (
    get('INTASEND_SIMULATE') === 'true' ||
    get('INTASEND_DISABLE_SIG_CHECK') === 'true'
  )
    throw new Error('Production payment simulation/bypass must be disabled');
  const result = {
    releaseCommit: get('RELEASE_COMMIT') || 'unknown',
    configuredDatabase: {
      host: connection.host,
      port: connection.port,
      database: connection.database,
      certificateVerification: connection.ssl?.rejectUnauthorized === true,
    },
    configuration: {
      googleAudience: Boolean(
        get('GOOGLE_CLIENT_ID')?.trim() || get('GOOGLE_WEB_CLIENT_ID')?.trim(),
      ),
      appleSignIn: [
        'APPLE_KEY_ID',
        'APPLE_TEAM_ID',
        'APPLE_BUNDLE_ID',
        'APPLE_PRIVATE_KEY',
      ].every((name) => Boolean(get(name)?.trim())),
      stripe: Boolean(get('STRIPE_SECRET_KEY') && get('STRIPE_WEBHOOK_SECRET')),
      emailProvider: get('EMAIL_PROVIDER') || 'MOCK',
      smsProvider: get('SMS_PROVIDER') || 'MOCK',
      firebaseCredentialFile: Boolean(
        get('FIREBASE_SERVICE_ACCOUNT_PATH') &&
        fs.existsSync(get('FIREBASE_SERVICE_ACCOUNT_PATH')),
      ),
    },
  };
  if (process.argv.includes('--configuration-only')) {
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  const client = new Client({
    host: connection.host,
    port: connection.port,
    user: connection.username,
    password: connection.password,
    database: connection.database,
    ssl: connection.ssl,
    connectionTimeoutMillis: 5000,
    query_timeout: 5000,
    application_name: 'paykey-read-only-production-audit',
    options: '-c default_transaction_read_only=on -c statement_timeout=5000',
  });
  try {
    await client.connect();
    await client.query('BEGIN READ ONLY');
    await client.query('SELECT 1');
    result.database = (
      await client.query(
        "SELECT current_database() AS database, inet_server_addr()::text AS server_address, inet_server_port() AS server_port, current_setting('transaction_read_only') AS read_only",
      )
    ).rows[0];
    result.tls = (
      await client.query(
        'SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid()',
      )
    ).rows[0] || { ssl: false };
    const exists = (
      await client.query("SELECT to_regclass('public.migrations') AS name")
    ).rows[0].name;
    const applied = exists
      ? (
          await client.query(
            'SELECT timestamp::text, name FROM public.migrations ORDER BY timestamp',
          )
        ).rows
      : [];
    const migrations = readMigrationIdentities(path.join(__dirname, '../dist/src/migrations'));
    const appliedNames = new Set(applied.map((entry) => entry.name));
    const pending = migrations.filter((migration) => !appliedNames.has(migration.name));
    result.migrations = {
      ledgerExists: Boolean(exists),
      applied,
      pendingFiles: pending.map((migration) => migration.file),
      pendingNames: pending.map((migration) => migration.name),
    };
    await client.query('ROLLBACK');
    console.log(JSON.stringify(result, null, 2));
    if (!result.tls.ssl) throw new Error('Database session is not encrypted');
    if (process.argv.includes('--require-migrations-current') && pending.length)
      throw new Error('Deployed image contains unapplied migrations');
  } finally {
    await client.end();
  }
}

audit().catch((error) => {
  // Native connection errors can include a connection string or supplied values.
  // Emit only our known-safe configuration messages or a generic failure/code.
  const safeMessage =
    /^(Production audit|Missing required configuration|JWT_SECRET or REDIS_PASSWORD|Production payment|Database session|Deployed image)/.test(
      error.message || '',
    )
      ? error.message
      : 'Read-only production audit failed; inspect connectivity and configuration securely';
  const code =
    typeof error.code === 'string' && /^[A-Z0-9_]+$/.test(error.code)
      ? ` (${error.code})`
      : '';
  console.error(safeMessage + code);
  process.exitCode = 1;
});
