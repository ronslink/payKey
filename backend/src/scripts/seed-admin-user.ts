/**
 * Seed Admin User
 *
 * Creates (or resets) the PayDome admin account used to log in
 * to the Admin Console SPA.
 *
 * Usage:
 *   npx ts-node -r tsconfig-paths/register src/scripts/seed-admin-user.ts
 *
 * Or after building:
 *   node dist/src/scripts/seed-admin-user.js
 *
 * The admin email + password can also be overridden via env vars:
 *   ADMIN_EMAIL=admin@yourcompany.com ADMIN_PASSWORD=SecurePass123! npx ts-node ...
 */

import 'reflect-metadata';
import * as bcrypt from 'bcrypt';
import { DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

// ─── Config ──────────────────────────────────────────────────────────────────
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@paydome.io';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'PayDome@Admin2024!';
const ADMIN_FIRST_NAME = 'PayDome';
const ADMIN_LAST_NAME = 'Admin';

// ─── DB Connection (minimal — only needs the users table) ────────────────────
const dbUrl = process.env.DATABASE_URL;

const dataSource = new DataSource(
    dbUrl
        ? {
            type: 'postgres',
            url: dbUrl,
            ssl: { rejectUnauthorized: false },
            entities: [path.resolve(__dirname, '../modules/users/entities/user.entity.{ts,js}')],
            synchronize: false,
        }
        : {
            type: 'postgres',
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '5432'),
            username: process.env.DB_USERNAME || process.env.DB_USER || 'paykey',
            password: process.env.DB_PASSWORD || 'Tina76',
            database: process.env.DB_NAME || 'paykey',
            entities: [path.resolve(__dirname, '../modules/users/entities/user.entity.{ts,js}')],
            synchronize: false,
        },
);

async function seedAdminUser() {
    console.log('🔐 Seeding Admin User');
    console.log('='.repeat(50));

    await dataSource.initialize();
    console.log('✅ Database connected');

    const userRepo = dataSource.getRepository('User');

    // Check if admin already exists
    let admin = await userRepo.findOne({ where: { email: ADMIN_EMAIL } });

    const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, 12);

    if (admin) {
        // Update existing — ensure role=ADMIN and refresh password
        await userRepo.update(admin.id, {
            role: 'ADMIN',
            passwordHash,
            firstName: ADMIN_FIRST_NAME,
            lastName: ADMIN_LAST_NAME,
            isOnboardingCompleted: true,
        });
        console.log(`✅ Admin user updated: ${ADMIN_EMAIL}`);
    } else {
        // Create new admin
        const newAdmin = userRepo.create({
            email: ADMIN_EMAIL,
            passwordHash,
            role: 'ADMIN',
            firstName: ADMIN_FIRST_NAME,
            lastName: ADMIN_LAST_NAME,
            isOnboardingCompleted: true,
            tier: 'PLATINUM',
        });
        await userRepo.save(newAdmin);
        console.log(`✅ Admin user created: ${ADMIN_EMAIL}`);
    }

    console.log('');
    console.log('🎉 Admin credentials:');
    console.log(`   Email:    ${ADMIN_EMAIL}`);
    console.log(`   Password: ${ADMIN_PASSWORD}`);
    console.log('');
    console.log('⚠️  Change the password after first login!');
    console.log('   (Or set ADMIN_EMAIL + ADMIN_PASSWORD env vars before running)');

    await dataSource.destroy();
    process.exit(0);
}

seedAdminUser().catch((err) => {
    console.error('❌ Failed to seed admin user:', err);
    process.exit(1);
});
