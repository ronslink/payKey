import { getDatabaseConnection } from './database-connection';
import { getDatabaseConfig } from './database.config';
import { ConfigService } from '@nestjs/config';

describe('production database configuration', () => {
  const url =
    'postgresql://app:p%40ss@db.example.com:25060/paykey?sslmode=no-verify';
  const read = (values: Record<string, string>) => (key: string) => values[key];

  it('requires a production URL even if local database credentials exist', () => {
    expect(() =>
      getDatabaseConnection(
        read({ NODE_ENV: 'production', DB_PASSWORD: 'local' }),
      ),
    ).toThrow('DATABASE_URL is required');
  });

  it('enforces certificate verification despite weakening URL parameters', () => {
    expect(
      getDatabaseConnection(
        read({ NODE_ENV: 'production', DATABASE_URL: url }),
      ),
    ).toEqual({
      host: 'db.example.com',
      port: 25060,
      username: 'app',
      password: 'p@ss',
      database: 'paykey',
      ssl: { rejectUnauthorized: true },
    });
  });

  it('does not leak malformed database credentials', () => {
    expect(() =>
      getDatabaseConnection(read({ DATABASE_URL: 'secret-do-not-log' })),
    ).toThrow('DATABASE_URL must contain');
  });

  it('never synchronizes or auto-migrates production, even with a sync flag', () => {
    const options = getDatabaseConfig(
      new ConfigService({
        NODE_ENV: 'production',
        DATABASE_URL: url,
        DB_SYNCHRONIZE: 'true',
      }),
    );
    expect(options.synchronize).toBe(false);
    expect(options.migrationsRun).toBe(false);
    expect(options.logging).toBe(false);
  });

  it('keeps local test databases available without TLS', () => {
    expect(
      getDatabaseConnection(read({ NODE_ENV: 'test', DB_PASSWORD: 'test' })),
    ).toMatchObject({ database: 'paykey_test', ssl: false });
  });
});
