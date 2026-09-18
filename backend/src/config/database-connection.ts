import { readFileSync } from 'fs';

type ReadConfig = (key: string) => string | undefined;
interface ConnectionOptions {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
  ssl: false | { rejectUnauthorized: true; ca?: string };
}

/** Shared by the server, migration CLI and read-only production audit. */
export function getDatabaseConnection(get: ReadConfig): ConnectionOptions {
  const production = get('NODE_ENV') === 'production';
  const databaseUrl = get('DATABASE_URL');
  if (production && !databaseUrl) {
    throw new Error('DATABASE_URL is required in production');
  }

  if (databaseUrl) {
    let parsed: URL;
    try {
      parsed = new URL(databaseUrl);
      if (!['postgres:', 'postgresql:'].includes(parsed.protocol))
        throw new Error();
      if (
        !parsed.hostname ||
        !parsed.username ||
        !parsed.password ||
        parsed.pathname.length < 2
      ) {
        throw new Error();
      }
    } catch {
      // Never include the URL or native parse error: both can contain credentials.
      throw new Error(
        'DATABASE_URL must contain a PostgreSQL host, database and credentials',
      );
    }

    const caPath = get('DB_SSL_CA_PATH');
    // Do not pass URL SSL query options to pg: sslmode can override the strict
    // SSL object. NODE_EXTRA_CA_CERTS is also supported by the Node TLS runtime.
    return {
      host: parsed.hostname,
      port: Number(parsed.port || 5432),
      username: decodeURIComponent(parsed.username),
      password: decodeURIComponent(parsed.password),
      database: decodeURIComponent(parsed.pathname.slice(1)),
      ssl: {
        rejectUnauthorized: true,
        ...(caPath ? { ca: readFileSync(caPath, 'utf8') } : {}),
      },
    };
  }

  const password = get('DB_PASSWORD');
  if (!password)
    throw new Error(
      'DB_PASSWORD must be provided when DATABASE_URL is not set',
    );
  const port = Number(get('DB_PORT') || 5432);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('DB_PORT must be a valid TCP port');
  }
  return {
    host: get('DB_HOST') || 'localhost',
    port,
    username: get('DB_USERNAME') || get('DB_USER') || 'paykey',
    password,
    database:
      get('DB_NAME') || (get('NODE_ENV') === 'test' ? 'paykey_test' : 'paykey'),
    ssl: false,
  };
}
