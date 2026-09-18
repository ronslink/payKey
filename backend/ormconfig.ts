import { DataSource } from 'typeorm';
import * as path from 'path';
import { getDatabaseConnection } from './src/config/database-connection';

// Running inside a compiled Docker image (dist/ exists, ts-node is absent)
const isProdBuild = process.env.NODE_ENV === 'production';

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
  ...getDatabaseConnection((key) => process.env[key]),
  entities: entitiesPath,
  migrations: migrationsPath,
  migrationsTableName: 'migrations', // Must match the table used by the app at runtime
  synchronize: false,
  migrationsRun: false,
});
