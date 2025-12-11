import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load env from backend root
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

async function checkTable() {
    try {
        console.log('Connecting to database...');
        console.log(`Host: ${process.env.DB_HOST || 'localhost'}`);
        console.log(`Port: ${process.env.DB_PORT || '5432'}`);

        await dataSource.initialize();
        console.log('✅ Connected!');

        const result = await dataSource.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'exports'
      );
    `);

        const exists = result[0].exists;
        if (exists) {
            console.log('✅ Table "exports" EXISTS.');
            process.exit(0);
        } else {
            console.error('❌ Table "exports" does NOT exist.');
            process.exit(1);
        }

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    } finally {
        if (dataSource.isInitialized) {
            await dataSource.destroy();
        }
    }
}

checkTable();
