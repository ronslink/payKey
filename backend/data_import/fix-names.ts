// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function fixNames() {
    console.log('📝 Fixing worker names to mixed case...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    try {
        // Fix KEFA -> Kefa
        await ds.query(`
            UPDATE workers SET name = 'Kefa, Nicholas Luvaga' 
            WHERE name = 'KEFA, Nicholas Luvaga'
        `);

        // Fix MUSULWA -> Musulwa
        await ds.query(`
            UPDATE workers SET name = 'Musulwa, Janet Ngoyisi' 
            WHERE name = 'MUSULWA, Janet Ngoyisi'
        `);

        const workers = await ds.query(`SELECT name FROM workers WHERE name LIKE '%Kefa%' OR name LIKE '%Musulwa%'`);
        console.log('✅ Names updated:');
        workers.forEach(w => console.log(`   - ${w.name}`));

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

fixNames();
