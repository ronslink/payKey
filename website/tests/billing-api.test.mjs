import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import ts from 'typescript';

// Compile the actual browser API module in memory with empty Vite configuration.
const source = (await fs.readFile(new URL('../src/lib/billing-api.ts', import.meta.url), 'utf8'))
  .replaceAll('import.meta.env', '({})');
const compiled = ts.transpileModule(source, {
  compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 },
}).outputText;
const api = await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`);
const store = new Map();
globalThis.sessionStorage = {
  getItem: key => store.get(key) ?? null,
  setItem: (key, value) => store.set(key, value),
  removeItem: key => store.delete(key),
};
globalThis.window = { location: { origin: 'https://paydome.co' } };
const reply = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json' },
});

test('hosted checkout accepts only the HTTPS Stripe checkout origin', () => {
  assert.equal(api.hostedCheckoutUrl('https://checkout.stripe.com/c/pay/cs_test_123'), 'https://checkout.stripe.com/c/pay/cs_test_123');
  for (const url of ['http://checkout.stripe.com/pay', 'https://checkout.stripe.com.evil.example/pay',
    'javascript:alert(1)', 'https://user:secret@checkout.stripe.com/pay', 'https://checkout.stripe.com:444/pay']) {
    assert.throws(() => api.hostedCheckoutUrl(url));
  }
});

test('post-login return paths cannot become an external redirect', () => {
  assert.equal(api.accountReturnPath('/checkout?plan=basic'), '/checkout?plan=basic');
  assert.equal(api.accountReturnPath('/payments/subscriptions/success?session_id=cs_test_123'), '/payments/subscriptions/success?session_id=cs_test_123');
  for (const path of ['https://evil.example', '//evil.example', '/\\evil.example/checkout', '/admin', null]) {
    assert.equal(api.accountReturnPath(path), null);
  }
  assert.equal(api.selectedPlan('unknown'), 'free');
});

test('signup sends no bearer token, saves session, then authenticates private reads', async () => {
  store.clear();
  const calls = [];
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return reply(url.endsWith('/auth/register') ? { access_token: 'mock-session-token' } : { tier: 'FREE' });
  };
  await api.authenticate('register', { email: 'test@example.invalid', password: 'test-only', firstName: 'Test' });
  assert.equal(calls[0].options.headers.Authorization, undefined);
  assert.equal(api.readSession().email, 'test@example.invalid');
  await api.apiRequest('/subscriptions/current');
  assert.equal(calls[1].options.headers.Authorization, 'Bearer mock-session-token');
  assert.equal(calls[1].options.credentials, 'omit');
  assert.equal(calls[1].options.cache, 'no-store');
});

test('private reads without a session never make a request', async () => {
  store.clear();
  globalThis.fetch = async () => { throw new Error('Must not request'); };
  await assert.rejects(api.apiRequest('/subscriptions/current'), error => error.status === 401);
});

test('expired sessions clear account data and propagate authorization errors', async () => {
  store.set('paydome.account.v1', JSON.stringify({ token: 'expired', email: 'test@example.invalid' }));
  store.set(api.CHECKOUT_KEY, 'cs_test_123');
  globalThis.fetch = async () => reply({ message: 'Unauthorized' }, 401);
  await assert.rejects(api.apiRequest('/subscriptions/current'), error => error.status === 401);
  assert.equal(api.readSession(), null);
  assert.equal(store.get(api.CHECKOUT_KEY), undefined);
});
