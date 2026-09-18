'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(
  path.join(__dirname, '../backend/scripts/audit-production.cjs'),
  'utf8',
);

function compiledMigration(className, explicitName) {
  return `class ${className} {
    ${explicitName === undefined ? '' : `name = '${explicitName}';`}
    async up() { throw new Error('Migration SQL must never execute during audit'); }
  }
  exports.${className} = ${className};`;
}

async function executeAudit({
  configurationOnly = false,
  connectionError,
  applied = [{ timestamp: '1700000000000', name: 'Fixture1700000000000' }],
  migrationFiles = { '1700000000000-fixture.js': compiledMigration('Fixture1700000000000') },
} = {}) {
  const commands = [];
  const output = [];
  const errors = [];
  const env = {
    NODE_ENV: 'production',
    DATABASE_URL: 'postgresql://audit:credential-must-stay-private@db.example.invalid/paykey',
    JWT_SECRET: 'test-signing-value-at-least-thirty-two-characters',
    REDIS_PASSWORD: 'test-password-at-least-sixteen-characters',
    INTASEND_PUBLISHABLE_KEY: 'test-public',
    INTASEND_SECRET_KEY: 'test-secret-must-stay-private',
    INTASEND_CHALLENGE: 'test-verifier-must-stay-private',
    STRIPE_SECRET_KEY: 'sk_live_test-must-stay-private',
    STRIPE_WEBHOOK_SECRET: 'whsec_test-must-stay-private',
  };
  let clientOptions;
  let closed = false;
  class Client {
    constructor(options) { clientOptions = options; }
    async connect() { if (connectionError) throw connectionError; }
    async query(sql) {
      commands.push(sql);
      if (sql.includes('current_database()')) return { rows: [{ database: 'paykey', read_only: 'on' }] };
      if (sql.includes('pg_stat_ssl')) return { rows: [{ ssl: true, version: 'TLSv1.3' }] };
      if (sql.includes('to_regclass')) return { rows: [{ name: 'migrations' }] };
      if (sql.includes('FROM public.migrations')) return { rows: applied };
      return { rows: [] };
    }
    async end() { closed = true; }
  }
  const fakeProcess = { env, argv: configurationOnly ? ['node', 'audit', '--configuration-only'] : ['node', 'audit', '--require-migrations-current'] };
  const modules = {
    'node:fs': {
      existsSync: () => false,
      readdirSync: () => Object.keys(migrationFiles),
      readFileSync: (filename) => migrationFiles[path.basename(filename)],
    },
    'node:path': path,
    pg: { Client },
    '../dist/src/config/database-connection.js': {
      getDatabaseConnection: () => ({
        host: 'db.example.invalid', port: 25060, username: 'audit',
        password: 'credential-must-stay-private', database: 'paykey',
        ssl: { rejectUnauthorized: true },
      }),
    },
  };
  vm.runInNewContext(source, {
    __dirname: path.join(__dirname, '../backend/scripts'),
    process: fakeProcess,
    require(name) {
      assert.ok(Object.hasOwn(modules, name), `Audit must not load application module ${name}`);
      return modules[name];
    },
    console: { log: (message) => output.push(message), error: (message) => errors.push(message) },
  });
  await new Promise((resolve) => setImmediate(resolve));
  return { commands, output, errors, clientOptions, closed, exitCode: fakeProcess.exitCode };
}

test('production audit uses read-only DB session, TLS and metadata queries without application startup', async () => {
  const result = await executeAudit();
  assert.equal(result.exitCode, undefined);
  assert.equal(result.clientOptions.ssl.rejectUnauthorized, true);
  assert.match(result.clientOptions.options, /default_transaction_read_only=on/);
  assert.equal(result.commands[0], 'BEGIN READ ONLY');
  assert.equal(result.commands.at(-1), 'ROLLBACK');
  assert.ok(result.commands.every((sql) => /^(SELECT|BEGIN READ ONLY|ROLLBACK)/.test(sql)));
  assert.equal(result.closed, true);
  const report = JSON.parse(result.output[0]);
  assert.deepEqual(report.migrations.pendingFiles, []);
  assert.doesNotMatch(result.output.join('\n'), /must-stay-private/);
});

test('configuration-only audit creates no database connection', async () => {
  const result = await executeAudit({ configurationOnly: true });
  assert.equal(result.clientOptions, undefined);
  assert.equal(result.commands.length, 0);
  assert.equal(result.exitCode, undefined);
  assert.equal(JSON.parse(result.output[0]).configuredDatabase.host, 'db.example.invalid');
});

test('connection errors cannot disclose native error credentials', async () => {
  const result = await executeAudit({ connectionError: Object.assign(new Error('credential-must-stay-private'), { code: 'ECONNREFUSED' }) });
  assert.equal(result.exitCode, 1);
  assert.equal(result.closed, true);
  assert.match(result.errors[0], /ECONNREFUSED/);
  assert.doesNotMatch(result.errors.join('\n'), /credential-must-stay-private/);
});

test('migration audit includes nonstandard filenames and distinguishes names sharing a timestamp', async () => {
  const timestamp = '1700000000000';
  const result = await executeAudit({
    applied: [{ timestamp, name: `InitialSchema${timestamp}` }],
    migrationFiles: {
      [`${timestamp}-InitialSchema.js`]: compiledMigration(`InitialSchema${timestamp}`),
      [`AlterSubscriptionPaymentsUserIdToUuid${timestamp}.js`]: compiledMigration(`AlterSubscriptionPaymentsUserIdToUuid${timestamp}`, `AlterSubscriptionPaymentsUserIdToUuid${timestamp}`),
      'add-promotional-items-and-campaigns.js': compiledMigration(`AddPromotionalItemsAndCampaigns${timestamp}`),
      [`${timestamp}-InitialSchema.js.map`]: 'not a migration',
    },
  });
  assert.equal(result.exitCode, 1);
  const report = JSON.parse(result.output[0]);
  assert.deepEqual(report.migrations.pendingNames, [
    `AlterSubscriptionPaymentsUserIdToUuid${timestamp}`,
    `AddPromotionalItemsAndCampaigns${timestamp}`,
  ]);
  assert.deepEqual(report.migrations.pendingFiles, [
    `AlterSubscriptionPaymentsUserIdToUuid${timestamp}.js`,
    'add-promotional-items-and-campaigns.js',
  ]);
  assert.match(result.errors[0], /unapplied migrations/);
  assert.equal(result.closed, true);
});

test('migration audit uses an explicit instance name and fails closed on unreadable metadata', async () => {
  const recognized = await executeAudit({
    migrationFiles: {
      'legacy-name.js': compiledMigration('Old$Class1700000000000', 'Fixture1700000000000'),
    },
  });
  assert.equal(recognized.exitCode, undefined);
  assert.deepEqual(JSON.parse(recognized.output[0]).migrations.pendingNames, []);

  const unsupported = await executeAudit({
    migrationFiles: { 'legacy-name.js': 'module.exports = createMigration();' },
  });
  assert.equal(unsupported.exitCode, 1);
  assert.match(unsupported.errors[0], /unsupported migration declaration/);
  assert.equal(unsupported.closed, true);
});

test('compiled repository migrations can all be inspected without loading their modules', async () => {
  const directory = path.join(__dirname, '../backend/dist/src/migrations');
  const migrationFiles = Object.fromEntries(fs.readdirSync(directory)
    .filter((file) => file.endsWith('.js'))
    .map((file) => [file, fs.readFileSync(path.join(directory, file), 'utf8')]));
  const result = await executeAudit({ applied: [], migrationFiles });
  assert.equal(result.exitCode, 1);
  assert.match(result.errors[0], /unapplied migrations/);
  const report = JSON.parse(result.output[0]);
  assert.equal(report.migrations.pendingNames.length, Object.keys(migrationFiles).length);
  assert.ok(report.migrations.pendingNames.includes('AddPromotionalItemsAndCampaigns1700000000000'));
  assert.ok(report.migrations.pendingNames.includes('UpdateSupportTicketCategoryEnum1700000000000'));
  assert.ok(report.migrations.pendingNames.includes('AlterSubscriptionPaymentsUserIdToUuid1700000000000'));
});
