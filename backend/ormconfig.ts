import { DataSource } from 'typeorm';
import * as path from 'path';

// CI detection - GitHub Actions sets these environment variables
const isCI = !!(process.env.CI || process.env.GITHUB_ACTIONS);

// Running inside a compiled Docker image (dist/ exists, ts-node is absent)
const isProdBuild = process.env.NODE_ENV === 'production';

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

// In production the app runs from /app; ormconfig.js compiles to /app/dist/ormconfig.js
// so __dirname === /app/dist. Migration/entity files live in /app/dist/src/.
// In development/CI ts-node runs from /app so __dirname === /app and files are .ts sources.
const entitiesPath = isProdBuild
  ? [path.join(__dirname, 'src/**/*.entity.js')]
  : ['src/**/*.entity.ts'];

const migrationsPath = isProdBuild
  ? [path.join(__dirname, 'src/migrations/*.js')]
  : ['src/migrations/*.ts'];

export default new DataSource({
  type: 'postgres',
  // Use DATABASE_URL if available, otherwise fall back to individual env vars
  host: dbConfig?.host || process.env.DB_HOST || (isCI ? 'localhost' : 'db'),
  port: dbConfig?.port || parseInt(process.env.DB_PORT || '5432'),
  username: dbConfig?.username || process.env.DB_USER || process.env.DB_USERNAME || 'paykey',
  password: dbConfig?.password || process.env.DB_PASSWORD || 'password',
  database: dbConfig?.database || process.env.DB_NAME || 'paykey_test',
  entities: entitiesPath,
  migrations: migrationsPath,
  migrationsTableName: 'migrations', // Must match the table used by the app at runtime
  synchronize: false,
  // Enable SSL for production (cloud databases like Aiven require it)
  ssl: dbUrl ? { rejectUnauthorized: false } : false,
});
