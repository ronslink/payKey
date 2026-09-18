// E2E tests must use provider doubles. Never contact live payment/email services.
if (process.env.DATABASE_URL) {
  throw new Error(
    'E2E tests require DATABASE_URL to be unset and a separate *_test database',
  );
}
if (process.env.DB_NAME && !process.env.DB_NAME.endsWith('_test')) {
  throw new Error('E2E tests may only use a database whose name ends in _test');
}
const nock = require('nock');
nock.disableNetConnect();
nock.enableNetConnect((host) =>
  /^(localhost|127\.0\.0\.1|\[?::1\]?)(:\d+)?$/.test(host),
);
