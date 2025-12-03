-- PayKey Database Schema
-- Based on TypeORM entities from the backend

-- Create necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
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
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Countries table
CREATE TABLE IF NOT EXISTS countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    currency VARCHAR NOT NULL,
    "isActive" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Properties table
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
);

-- Workers table
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
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Pay periods table
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
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payroll records table
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
);

-- Tax submissions table
CREATE TABLE IF NOT EXISTS tax_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "payPeriodId" UUID NOT NULL REFERENCES pay_periods(id) ON DELETE CASCADE,
    "totalPaye" DECIMAL(12,2) DEFAULT 0,
    "totalNssf" DECIMAL(12,2) DEFAULT 0,
    "totalNhif" DECIMAL(12,2) DEFAULT 0,
    "totalHousingLevy" DECIMAL(12,2) DEFAULT 0,
    status VARCHAR DEFAULT 'PENDING',
    "filingDate" TIMESTAMP WITH TIME ZONE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tax tables table
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
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "workerId" UUID REFERENCES workers(id) ON DELETE SET NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    currency VARCHAR DEFAULT 'KES',
    type VARCHAR NOT NULL,
    status VARCHAR DEFAULT 'PENDING',
    "providerRef" VARCHAR,
    "propertyId" UUID REFERENCES properties(id) ON DELETE SET NULL,
    metadata JSONB,
    "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_workers_userId ON workers("userId");
CREATE INDEX IF NOT EXISTS idx_workers_propertyId ON workers("propertyId");
CREATE INDEX IF NOT EXISTS idx_pay_periods_userId ON pay_periods("userId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_userId ON payroll_records("userId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_workerId ON payroll_records("workerId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_payPeriodId ON payroll_records("payPeriodId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_period ON payroll_records("periodStart", "periodEnd");
CREATE INDEX IF NOT EXISTS idx_tax_submissions_userId ON tax_submissions("userId");
CREATE INDEX IF NOT EXISTS idx_tax_submissions_payPeriodId ON tax_submissions("payPeriodId");
CREATE INDEX IF NOT EXISTS idx_transactions_userId ON transactions("userId");
CREATE INDEX IF NOT EXISTS idx_transactions_workerId ON transactions("workerId");
CREATE INDEX IF NOT EXISTS idx_transactions_payPeriodId ON transactions("payPeriodId");