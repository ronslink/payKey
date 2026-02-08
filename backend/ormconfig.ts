import { DataSource } from 'typeorm';

// CI detection - GitHub Actions sets these environment variables
const isCI = !!(process.env.CI || process.env.GITHUB_ACTIONS);

// Parse DATABASE_URL if available (used in production)
function parseDbUrl(url: string) {
  const parsed = new URL(url);
  return {
    host: parsed.hostname,
    port: parseInt(parsed.port || '5432'),
    username: parsed.username,
    password: parsed.password,
    database: parsed.pathname.slice(1), // Remove leading '/'
  };
}

const dbUrl = process.env.DATABASE_URL;
const dbConfig = dbUrl ? parseDbUrl(dbUrl) : null;

export default new DataSource({
  type: 'postgres',
  // Use DATABASE_URL if available, otherwise fall back to individual env vars
  host: dbConfig?.host || process.env.DB_HOST || (isCI ? 'localhost' : 'db'),
  port: dbConfig?.port || parseInt(process.env.DB_PORT || '5432'),
  username: dbConfig?.username || process.env.DB_USER || process.env.DB_USERNAME || 'paykey',
  password: dbConfig?.password || process.env.DB_PASSWORD || 'password',
  database: dbConfig?.database || process.env.DB_NAME || 'paykey_test',
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/migrations/*.ts'],
  synchronize: false,
  // Enable SSL for production (cloud databases like Aiven require it)
  ssl: dbUrl ? { rejectUnauthorized: false } : false,
});
