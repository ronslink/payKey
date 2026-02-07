import { DataSource } from 'typeorm';

// CI detection - GitHub Actions sets these environment variables
const isCI = !!(process.env.CI || process.env.GITHUB_ACTIONS);

export default new DataSource({
  type: 'postgres',
  // In CI, default to localhost; in Docker, default to 'db' service name
  host: process.env.DB_HOST || (isCI ? 'localhost' : 'db'),
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER || process.env.DB_USERNAME || 'paykey',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'paykey_test',
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/migrations/*.ts'],
  synchronize: false,
});
