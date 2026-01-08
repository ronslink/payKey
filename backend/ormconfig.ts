import { DataSource } from 'typeorm';

export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'db', // Use 'db' service name in Docker, fallback to localhost for local development
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER || process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  database: process.env.DB_NAME || 'paykey',
  entities: ['dist/src/modules/**/*.entity.js'],
  migrations: ['dist/src/migrations/*.js'],
  synchronize: false,
});
