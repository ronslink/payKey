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

test('M-Pesa uses the reviewed server KES quote and activates only after paid entitlement confirmation', async () => {
  store.set('paydome.account.v1', JSON.stringify({ token: 'owner-session', email: 'owner@example.invalid' }));
  const paymentId = 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa';
  const quote = { planId: 'BASIC', billingPeriod: 'yearly', amount: 13000, currency: 'KES', periodStart: '2026-09-18T00:00:00Z', periodEnd: '2027-09-18T00:00:00Z', renewalMode: 'manual' };
  const calls = [];
  const statuses = [
    { status: 'PENDING', entitlementActive: true }, // Existing access is not this receipt's payment confirmation.
    { status: 'COMPLETED', entitlementActive: false },
    { status: 'COMPLETED', entitlementActive: true },
  ];
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    if (url.endsWith('/mpesa-quote')) return reply(quote);
    if (url.endsWith('/mpesa-subscribe')) return reply({ paymentId });
    return reply({ paymentId, ...statuses.shift(), amount: 13000, currency: 'KES' });
  };
  const reviewed = await api.quoteMpesaSubscription('basic', 'yearly');
  assert.equal(api.isMpesaPaymentMethod('mpesa'), true); // Backend enum serialization must keep pending recovery reachable.
  assert.equal(api.isMpesaPaymentMethod('MPESA'), true);
  assert.equal(api.isMpesaPaymentMethod('stripe'), false);
  await api.startMpesaSubscription(reviewed, '0712 345 678');
  assert.deepEqual(JSON.parse(calls[1].options.body), {
    planId: 'BASIC', billingPeriod: 'yearly', expectedAmount: 13000, phoneNumber: '254712345678',
  });
  assert.equal((await api.readMpesaSubscriptionPayment(paymentId)).entitlementActive, false);
  assert.equal((await api.readMpesaSubscriptionPayment(paymentId)).entitlementActive, false);
  assert.equal((await api.readMpesaSubscriptionPayment(paymentId)).entitlementActive, true);
  assert.ok(calls.every(call => call.options.headers.Authorization === 'Bearer owner-session'));
  assert.equal(calls.filter(call => call.url.endsWith('/mpesa-subscribe')).length, 1);
  assert.ok(calls.slice(2).every(call => call.options.method === 'GET'));
});

test('a mismatched quote cannot be displayed as the selected M-Pesa offer', async () => {
  store.set('paydome.account.v1', JSON.stringify({ token: 'owner-session', email: 'owner@example.invalid' }));
  globalThis.fetch = async () => reply({ planId: 'BASIC', billingPeriod: 'monthly', amount: 9.99, currency: 'USD', renewalMode: 'manual' });
  await assert.rejects(api.quoteMpesaSubscription('basic', 'monthly'), /valid M-Pesa price/);
  globalThis.fetch = async () => reply({ planId: 'BASIC', billingPeriod: 'monthly', amount: 1300, currency: 'KES', renewalMode: 'manual', periodStart: '2026-09-18T00:00:00Z', periodEnd: '2026-09-18T00:00:00Z' });
  await assert.rejects(api.quoteMpesaSubscription('basic', 'monthly'), /valid M-Pesa price/);
});

test('failed M-Pesa attempts stay failed and another receipt cannot confirm them', async () => {
  store.set('paydome.account.v1', JSON.stringify({ token: 'owner-session', email: 'owner@example.invalid' }));
  const paymentId = 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa';
  globalThis.fetch = async () => reply({ paymentId, status: 'FAILED', entitlementActive: true });
  assert.deepEqual(await api.readMpesaSubscriptionPayment(paymentId), { paymentStatus: 'failed', entitlementActive: false });
  globalThis.fetch = async () => reply({ paymentId: 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb', status: 'COMPLETED', entitlementActive: true });
  await assert.rejects(api.readMpesaSubscriptionPayment(paymentId), /unexpected payment status/);
});

test('invalid M-Pesa phone numbers and payment references never make provider requests', async () => {
  globalThis.fetch = async () => { throw new Error('Must not request'); };
  await assert.rejects(api.startMpesaSubscription({ planId: 'BASIC', billingPeriod: 'monthly', amount: 1300 }, '+49 123456789'), /Kenyan M-Pesa number/);
  await assert.rejects(api.readMpesaSubscriptionPayment('../other-account'), /Invalid payment reference/);
});
