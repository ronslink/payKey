import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import ts from 'typescript';

function moduleUrl(source) {
  const compiled = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  return `data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`;
}

const billingSource = (await fs.readFile(new URL('../src/lib/billing-api.ts', import.meta.url), 'utf8'))
  .replaceAll('import.meta.env', '({})');
const deletionSource = (await fs.readFile(new URL('../src/lib/account-deletion-api.ts', import.meta.url), 'utf8'))
  .replace("'./billing-api'", JSON.stringify(moduleUrl(billingSource)));
const { requestAccountDeletion } = await import(moduleUrl(deletionSource));
const store = new Map();
globalThis.sessionStorage = {
  getItem: key => store.get(key) ?? null,
  setItem: (key, value) => store.set(key, value),
  removeItem: key => store.delete(key),
};
const session = () => store.set('paydome.account.v1', JSON.stringify({ token: 'owner-token', email: 'owner@example.invalid' }));
const reply = (body, status = 202) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json' },
});

test('a password account can request deletion without a website session', async () => {
  store.clear();
  let call;
  globalThis.fetch = async (url, options) => {
    call = { url, options };
    return reply({ requestId: 'accepted-request' });
  };
  assert.equal((await requestAccountDeletion({ email: ' Owner@example.invalid ', password: 'test-password' })).requestId, 'accepted-request');
  assert.equal(call.url, 'https://api.paydome.co/data-deletion/request');
  assert.equal(call.options.headers.Authorization, undefined);
  assert.deepEqual(JSON.parse(call.options.body), { email: 'owner@example.invalid', password: 'test-password' });
});

test('a signed-in passwordless account uses authenticated ownership verification', async () => {
  store.clear(); session();
  let call;
  globalThis.fetch = async (url, options) => {
    call = { url, options };
    return reply({ requestId: 'accepted-owner-request' });
  };
  await requestAccountDeletion({ email: 'OWNER@example.invalid', reason: ' Leaving ' });
  assert.equal(call.url, 'https://api.paydome.co/data-deletion/request/me');
  assert.equal(call.options.headers.Authorization, 'Bearer owner-token');
  assert.deepEqual(JSON.parse(call.options.body), { email: 'owner@example.invalid', reason: 'Leaving' });
});

test('a signed-in account cannot request deletion for another email', async () => {
  store.clear(); session();
  globalThis.fetch = async () => { throw new Error('Must not request'); };
  await assert.rejects(requestAccountDeletion({ email: 'other@example.invalid', password: 'test-password' }), /only request deletion of the account you are signed in to/);
});

test('a public passwordless request is directed to ownership support without an API mutation', async () => {
  store.clear();
  globalThis.fetch = async () => { throw new Error('Must not request'); };
  await assert.rejects(requestAccountDeletion({ email: 'owner@example.invalid' }), /contact support@paydome.co so we can verify ownership/);
});

test('an expired owner session fails without retrying through the public deletion endpoint', async () => {
  store.clear(); session();
  const calls = [];
  globalThis.fetch = async url => {
    calls.push(url);
    return reply({ message: 'Unauthorized' }, 401);
  };
  await assert.rejects(requestAccountDeletion({ email: 'owner@example.invalid' }), error => error.status === 401);
  assert.deepEqual(calls, ['https://api.paydome.co/data-deletion/request/me']);
  assert.equal(store.has('paydome.account.v1'), false);
});

test('a billing rejection or missing confirmation is not reported as a received deletion request', async () => {
  store.clear();
  globalThis.fetch = async () => reply({ message: 'Cancel the recurring subscription before deleting this account.' }, 400);
  await assert.rejects(requestAccountDeletion({ email: 'owner@example.invalid', password: 'test-password' }), /Cancel the recurring subscription/);
  globalThis.fetch = async () => reply({ message: 'Accepted' });
  await assert.rejects(requestAccountDeletion({ email: 'owner@example.invalid', password: 'test-password' }), /did not confirm your deletion request/);
});
