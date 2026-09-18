import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { getJwtOptions, getJwtSecret } from './jwt.config';
import { JwtStrategy } from './jwt.strategy';

describe('JWT configuration', () => {
  const originalEnvironment = process.env.NODE_ENV;

  afterEach(() => {
    if (originalEnvironment === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = originalEnvironment;
  });

  const config = (values: Record<string, string>) =>
    ({
      get: (key: string) => values[key],
    }) as ConfigService;

  it.each(['', '   ', 'supersecretkey', 'paykey-development-only-jwt-secret'])(
    'rejects missing or development production secrets (%s)',
    (secret) => {
      process.env.NODE_ENV = 'production';
      const values = config({ JWT_SECRET: secret });
      expect(() => getJwtOptions(values)).toThrow('JWT_SECRET');
      expect(() => new JwtStrategy(values)).toThrow('JWT_SECRET');
    },
  );

  it('also enforces production configuration supplied through ConfigService', () => {
    process.env.NODE_ENV = 'test';
    expect(() => getJwtSecret(config({ NODE_ENV: 'production' }))).toThrow(
      'JWT_SECRET',
    );
  });

  it('uses the same configured secret for signing and verification', () => {
    process.env.NODE_ENV = 'production';
    const values = config({
      JWT_SECRET: 'private-production-test-secret-with-sufficient-length',
    });
    const signer = new JwtService(getJwtOptions(values));
    const token = signer.sign({ sub: 'test-user' });
    expect(
      signer.verify(token, { secret: getJwtSecret(values) }),
    ).toMatchObject({ sub: 'test-user' });
    expect(() => new JwtStrategy(values)).not.toThrow();
  });

  it('permits a development-only fallback for local and test execution', () => {
    process.env.NODE_ENV = 'test';
    expect(getJwtSecret(config({}))).toBeTruthy();
  });
});
