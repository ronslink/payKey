import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(__dirname, '../.env') });

const dataSource = new DataSource({
    type: 'postgres',
    host: 'localhost',
    port: 5435,
    username: process.env.DB_USER || process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'admin',
    database: process.env.DB_NAME || 'paykey',
    synchronize: false,
    logging: ['error'],
    entities: [],
});

async function createTable() {
    try {
        await dataSource.initialize();
        console.log('✅ Connected!');

        console.log('Recreating "exports" table...');
        await dataSource.query('DROP TABLE IF EXISTS "exports"');
        await dataSource.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');

        await dataSource.query(`
      CREATE TABLE IF NOT EXISTS "exports" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "exportType" character varying NOT NULL,
        "startDate" date NOT NULL,
        "endDate" date NOT NULL,
        "fileName" character varying NOT NULL,
        "filePath" character varying,
        "recordCount" integer NOT NULL DEFAULT 0,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_exports_id" PRIMARY KEY ("id")
      );
    `);
        // Note: userId FK constraint is optional for verification but good practice.
        // Assuming "users" table exists and PK is id.
        // await dataSource.query(`ALTER TABLE "exports" ADD CONSTRAINT "FK_exports_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);

        console.log('✅ Table "exports" created successfully.');

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    } finally {
        await dataSource.destroy();
    }
}

createTable();
