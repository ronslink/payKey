-- Fix missing tables and columns for payroll system

-- 1. Create tax_configs table
CREATE TABLE IF NOT EXISTS tax_configs (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "taxType" varchar NOT NULL,
    "rateType" varchar NOT NULL,
    "effectiveFrom" date NOT NULL,
    "effectiveTo" date NULL,
    "configuration" jsonb NOT NULL,
    "paymentDeadline" varchar DEFAULT '9th of following month',
    "isActive" boolean DEFAULT true,
    "notes" text NULL,
    "createdAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_tax_configs_id" PRIMARY KEY ("id")
);

-- 2. Create tax_submissions table
CREATE TABLE IF NOT EXISTS tax_submissions (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "userId" uuid NOT NULL,
    "payPeriodId" uuid NOT NULL,
    "totalPaye" decimal(15,2) DEFAULT 0,
    "totalNssf" decimal(15,2) DEFAULT 0,
    "totalNhif" decimal(15,2) DEFAULT 0,
    "totalHousingLevy" decimal(15,2) DEFAULT 0,
    "status" varchar DEFAULT 'pending',
    "filingDate" timestamp NULL,
    "createdAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_tax_submissions_id" PRIMARY KEY ("id")
);

-- 3. Create activities table
CREATE TABLE IF NOT EXISTS activities (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "userId" uuid NOT NULL,
    "type" varchar NOT NULL,
    "title" varchar NOT NULL,
    "description" text NULL,
    "metadata" jsonb NULL,
    "createdAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_activities_id" PRIMARY KEY ("id")
);

-- 4. Create account_mappings table
CREATE TABLE IF NOT EXISTS account_mappings (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "userId" uuid NOT NULL,
    "accountType" varchar NOT NULL,
    "accountName" varchar NOT NULL,
    "accountCode" varchar NULL,
    "isActive" boolean DEFAULT true,
    "createdAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_account_mappings_id" PRIMARY KEY ("id")
);

-- 5. Add missing columns to payroll_records table
DO $$ 
BEGIN
    -- Add payPeriodId column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payroll_records' AND column_name = 'payPeriodId'
    ) THEN
        ALTER TABLE payroll_records ADD COLUMN "payPeriodId" uuid;
    END IF;

    -- Add bonuses column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payroll_records' AND column_name = 'bonuses'
    ) THEN
        ALTER TABLE payroll_records ADD COLUMN "bonuses" decimal(15,2) DEFAULT 0;
    END IF;

    -- Add otherEarnings column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payroll_records' AND column_name = 'otherEarnings'
    ) THEN
        ALTER TABLE payroll_records ADD COLUMN "otherEarnings" decimal(15,2) DEFAULT 0;
    END IF;

    -- Add otherDeductions column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payroll_records' AND column_name = 'otherDeductions'
    ) THEN
        ALTER TABLE payroll_records ADD COLUMN "otherDeductions" decimal(15,2) DEFAULT 0;
    END IF;
END $$;

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS "IDX_tax_configs_taxType_effectiveFrom" ON tax_configs ("taxType", "effectiveFrom");
CREATE INDEX IF NOT EXISTS "IDX_tax_configs_isActive" ON tax_configs ("isActive");
CREATE INDEX IF NOT EXISTS "IDX_tax_submissions_userId_payPeriodId" ON tax_submissions ("userId", "payPeriodId");
CREATE INDEX IF NOT EXISTS "IDX_activities_userId_createdAt" ON activities ("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "IDX_payroll_records_payPeriodId" ON payroll_records ("payPeriodId");
CREATE INDEX IF NOT EXISTS "IDX_payroll_records_userId_payPeriodId" ON payroll_records ("userId", "payPeriodId");

-- 7. Insert seed tax configurations for 2025/2026
INSERT INTO tax_configs ("taxType", "rateType", "effectiveFrom", "effectiveTo", "configuration", "paymentDeadline", "isActive", "notes") VALUES 
-- PAYE - Graduated rates effective July 2023
('PAYE', 'GRADUATED', '2023-07-01', NULL, 
 '{
   "brackets": [
     {"from": 0, "to": 24000, "rate": 0.1},
     {"from": 24001, "to": 32333, "rate": 0.25},
     {"from": 32334, "to": 500000, "rate": 0.3},
     {"from": 500001, "to": 800000, "rate": 0.325},
     {"from": 800001, "to": null, "rate": 0.35}
   ],
   "personalRelief": 2400,
   "insuranceRelief": 0.15,
   "maxInsuranceRelief": 5000
 }', 
 '9th of following month', true, 'PAYE rates effective July 1, 2023'),

-- SHIF - Effective October 2024 (replaced NHIF)
('SHIF', 'PERCENTAGE', '2024-10-01', NULL,
 '{
   "percentage": 2.75,
   "minAmount": 300,
   "maxAmount": null
 }',
 '9th of following month', true,
 'SHIF 2.75% of gross salary, min KES 300, no cap. Replaced NHIF Oct 1, 2024'),

-- NSSF Tier 1 - Effective February 2025
('NSSF_TIER1', 'TIERED', '2025-02-01', NULL,
 '{
   "tiers": [
     {
       "name": "Tier I",
       "salaryFrom": 0,
       "salaryTo": 8000,
       "rate": 0.06
     }
   ]
 }',
 '9th of following month', true,
 'NSSF Tier I: 6% of first KES 8,000 (KES 480 each party)'),

-- NSSF Tier 2 - Effective February 2025
('NSSF_TIER2', 'TIERED', '2025-02-01', NULL,
 '{
   "tiers": [
     {
       "name": "Tier II", 
       "salaryFrom": 8001,
       "salaryTo": 72000,
       "rate": 0.06
     }
   ]
 }',
 '9th of following month', true,
 'NSSF Tier II: 6% of KES 8,001-72,000 (max KES 3,840 each party)'),

-- Housing Levy - Effective March 2024
('HOUSING_LEVY', 'PERCENTAGE', '2024-03-19', NULL,
 '{
   "percentage": 1.5,
   "minAmount": null,
   "maxAmount": null
 }',
 '9th working day after end of month', true,
 'Housing Levy: 1.5% employee + 1.5% employer. Fully tax-deductible from Dec 27, 2024')

ON CONFLICT DO NOTHING;

-- 8. Create sample activities for testing
INSERT INTO activities ("userId", "type", "title", "description", "metadata") 
SELECT 
    u.id,
    'SYSTEM',
    'Database Schema Updated',
    'Fixed missing tables and columns for payroll system',
    '{"action": "schema_fix", "tables": ["tax_configs", "tax_submissions", "activities", "account_mappings"]}'
FROM users u 
WHERE u.email = 'testuser@paykey.com'
ON CONFLICT DO NOTHING;

COMMIT;