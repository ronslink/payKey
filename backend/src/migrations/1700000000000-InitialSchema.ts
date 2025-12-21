import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Initial migration that creates all base tables.
 * This migration creates the core schema that other migrations depend on.
 * Uses IF NOT EXISTS for idempotency - safe to run on existing databases.
 */
export class InitialSchema1700000000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // Create uuid-ossp extension
        await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

        // Create enums
        await queryRunner.query(`
            DO $$ BEGIN
                CREATE TYPE users_idtype_enum AS ENUM ('NATIONAL_ID', 'ALIEN_ID', 'PASSPORT');
            EXCEPTION
                WHEN duplicate_object THEN null;
            END $$;
        `);

        await queryRunner.query(`
            DO $$ BEGIN
                CREATE TYPE payroll_frequency_enum AS ENUM ('WEEKLY', 'BI_WEEKLY', 'MONTHLY');
            EXCEPTION
                WHEN duplicate_object THEN null;
            END $$;
        `);

        // Users table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS users (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                email VARCHAR UNIQUE NOT NULL,
                "passwordHash" VARCHAR NOT NULL,
                role VARCHAR DEFAULT 'USER' NOT NULL,
                "firstName" VARCHAR,
                "lastName" VARCHAR,
                tier VARCHAR DEFAULT 'FREE',
                "stripeCustomerId" VARCHAR,
                "kraPin" VARCHAR,
                "nssfNumber" VARCHAR,
                "nhifNumber" VARCHAR,
                "idNumber" VARCHAR,
                address VARCHAR,
                city VARCHAR,
                "countryId" UUID,
                isresident BOOLEAN DEFAULT true,
                countryoforigin VARCHAR,
                "isOnboardingCompleted" BOOLEAN DEFAULT false,
                idtype users_idtype_enum,
                nationalityid VARCHAR,
                "defaultPayrollFrequency" payroll_frequency_enum DEFAULT 'MONTHLY',
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Countries table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS countries (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                code VARCHAR UNIQUE NOT NULL,
                name VARCHAR NOT NULL,
                currency VARCHAR NOT NULL,
                "isActive" BOOLEAN DEFAULT true,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Properties table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS properties (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                name VARCHAR NOT NULL,
                address VARCHAR NOT NULL,
                latitude DECIMAL(10,8),
                longitude DECIMAL(11,8),
                "geofenceRadius" INTEGER DEFAULT 100,
                "isActive" BOOLEAN DEFAULT true,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Workers table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS workers (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "employmentType" VARCHAR DEFAULT 'FIXED',
                "hourlyRate" DECIMAL(10,2),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                name VARCHAR NOT NULL,
                "phoneNumber" VARCHAR NOT NULL,
                "idNumber" VARCHAR,
                "kraPin" VARCHAR,
                "salaryGross" DECIMAL(12,2) NOT NULL,
                "startDate" DATE NOT NULL,
                "isActive" BOOLEAN DEFAULT true,
                "leaveBalance" INTEGER DEFAULT 0,
                email VARCHAR,
                "nssfNumber" VARCHAR,
                "nhifNumber" VARCHAR,
                "jobTitle" VARCHAR,
                "housingAllowance" DECIMAL(12,2) DEFAULT 0,
                "transportAllowance" DECIMAL(12,2) DEFAULT 0,
                "paymentFrequency" VARCHAR DEFAULT 'MONTHLY',
                "paymentMethod" VARCHAR DEFAULT 'MPESA',
                "mpesaNumber" VARCHAR,
                "bankName" VARCHAR,
                "bankAccount" VARCHAR,
                notes TEXT,
                "terminationId" UUID,
                "terminatedAt" TIMESTAMP WITH TIME ZONE,
                "propertyId" UUID REFERENCES properties(id) ON DELETE SET NULL,
                "emergencyContactName" VARCHAR,
                "emergencyContactPhone" VARCHAR,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Pay periods table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS pay_periods (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                name VARCHAR NOT NULL,
                "startDate" DATE NOT NULL,
                "endDate" DATE NOT NULL,
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "payDate" DATE,
                frequency VARCHAR DEFAULT 'MONTHLY',
                status VARCHAR DEFAULT 'DRAFT',
                "totalGrossAmount" DECIMAL(15,2) DEFAULT 0,
                "totalNetAmount" DECIMAL(15,2) DEFAULT 0,
                "totalTaxAmount" DECIMAL(15,2) DEFAULT 0,
                "totalWorkers" INTEGER DEFAULT 0,
                "processedWorkers" INTEGER DEFAULT 0,
                notes JSONB,
                "createdBy" UUID,
                "approvedBy" UUID,
                "approvedAt" TIMESTAMP WITH TIME ZONE,
                "processedAt" TIMESTAMP WITH TIME ZONE,
                "isOffCycle" BOOLEAN DEFAULT false,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Payroll records table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS payroll_records (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "workerId" UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
                "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL,
                "periodStart" DATE NOT NULL,
                "periodEnd" DATE NOT NULL,
                "grossSalary" DECIMAL(10,2) NOT NULL,
                "netSalary" DECIMAL(10,2) NOT NULL,
                "taxAmount" DECIMAL(10,2) NOT NULL,
                "paymentStatus" VARCHAR DEFAULT 'pending',
                "paymentMethod" VARCHAR DEFAULT 'mpesa',
                "paymentDate" TIMESTAMP WITH TIME ZONE,
                "taxBreakdown" JSONB,
                deductions JSONB,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Subscriptions table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS subscriptions (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                tier VARCHAR NOT NULL,
                status VARCHAR DEFAULT 'pending',
                amount DECIMAL(12,2) NOT NULL,
                currency VARCHAR DEFAULT 'KES',
                "startDate" TIMESTAMP WITH TIME ZONE,
                "endDate" TIMESTAMP WITH TIME ZONE,
                "nextBillingDate" TIMESTAMP WITH TIME ZONE,
                "stripeSubscriptionId" VARCHAR,
                "stripePriceId" VARCHAR,
                notes TEXT
            )
        `);

        // Tax tables table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS tax_tables (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                year INTEGER NOT NULL,
                "effectiveDate" DATE NOT NULL,
                "nssfConfig" JSONB NOT NULL,
                "nhifConfig" JSONB NOT NULL,
                "housingLevyRate" DECIMAL(5,4) NOT NULL,
                "payeBands" JSONB NOT NULL,
                "personalRelief" DECIMAL(12,2) NOT NULL,
                "isActive" BOOLEAN DEFAULT true,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Tax payments table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS tax_payments (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL,
                tax_type VARCHAR NOT NULL,
                amount DECIMAL(12,2) NOT NULL,
                currency VARCHAR DEFAULT 'KES',
                status VARCHAR DEFAULT 'pending',
                "dueDate" DATE,
                "paymentDate" DATE,
                notes TEXT
            )
        `);

        // Transactions table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS transactions (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "workerId" UUID REFERENCES workers(id) ON DELETE SET NULL,
                amount DECIMAL(12,2) NOT NULL,
                currency VARCHAR DEFAULT 'KES',
                type VARCHAR NOT NULL,
                status VARCHAR DEFAULT 'PENDING',
                "providerRef" VARCHAR,
                "propertyId" UUID REFERENCES properties(id) ON DELETE SET NULL,
                metadata JSONB,
                "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL,
                "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        `);

        // Create essential indexes
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_workers_userId ON workers("userId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_pay_periods_userId ON pay_periods("userId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_payroll_records_userId ON payroll_records("userId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_payroll_records_workerId ON payroll_records("workerId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_transactions_userId ON transactions("userId")`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Drop tables in reverse order of dependencies
        await queryRunner.query(`DROP TABLE IF EXISTS transactions CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS tax_payments CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS tax_tables CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS subscriptions CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS payroll_records CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS pay_periods CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS workers CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS properties CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS countries CASCADE`);
        await queryRunner.query(`DROP TABLE IF EXISTS users CASCADE`);
        await queryRunner.query(`DROP TYPE IF EXISTS payroll_frequency_enum`);
        await queryRunner.query(`DROP TYPE IF EXISTS users_idtype_enum`);
    }
}
