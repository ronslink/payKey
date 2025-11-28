-- PayKey Database Initialization Script
-- This script wipes the database and recreates it with the latest schema and seed data.

-- 1. Reset Schema
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- 2. Create Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. Define Schema (Updated with new User fields)

-- Enum for idtype
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'users_idtype_enum') THEN
        CREATE TYPE users_idtype_enum AS ENUM ('NATIONAL_ID', 'ALIEN_ID', 'PASSPORT');
    END IF;
END$$;

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
    isresident BOOLEAN DEFAULT true,
    countryoforigin VARCHAR,
    "isOnboardingCompleted" BOOLEAN DEFAULT false,
    idtype users_idtype_enum,
    nationalityid VARCHAR,
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

-- tax_submissions table removed for debugging

-- Subscriptions table
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
);

-- Subscription Payment History table
CREATE TABLE IF NOT EXISTS subscription_payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "subscriptionId" UUID NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR DEFAULT 'KES',
    status VARCHAR DEFAULT 'pending',
    "paymentDate" DATE,
    "stripePaymentIntentId" VARCHAR,
    "billingPeriodStart" DATE,
    "billingPeriodEnd" DATE
);
-- Tax payments table
CREATE TABLE IF NOT EXISTS tax_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL,
    -- "taxSubmissionId" UUID REFERENCES tax_submissions(id) ON DELETE SET NULL,
    tax_type VARCHAR NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR DEFAULT 'KES',
    status VARCHAR DEFAULT 'pending',
    "dueDate" DATE,
    "paymentDate" DATE,
    notes TEXT
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_workers_userId ON workers("userId");
CREATE INDEX IF NOT EXISTS idx_workers_propertyId ON workers("propertyId");
CREATE INDEX IF NOT EXISTS idx_pay_periods_userId ON pay_periods("userId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_userId ON payroll_records("userId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_workerId ON payroll_records("workerId");
CREATE INDEX IF NOT EXISTS idx_payroll_records_period ON payroll_records("periodStart", "periodEnd");
-- CREATE INDEX IF NOT EXISTS idx_tax_submissions_userId ON tax_submissions("userId");
-- CREATE INDEX IF NOT EXISTS idx_tax_submissions_payPeriodId ON tax_submissions("payPeriodId");
CREATE INDEX IF NOT EXISTS idx_transactions_userId ON transactions("userId");
CREATE INDEX IF NOT EXISTS idx_transactions_workerId ON transactions("workerId");
CREATE INDEX IF NOT EXISTS idx_transactions_payPeriodId ON transactions("payPeriodId");

-- 4. Seed Data

-- Countries
INSERT INTO countries (code, name, currency, "isActive") VALUES
('AF', 'Afghanistan', 'AFN', true),
('AL', 'Albania', 'ALL', true),
('DZ', 'Algeria', 'DZD', true),
('AO', 'Angola', 'AOA', true),
('AR', 'Argentina', 'ARS', true),
('AM', 'Armenia', 'AMD', true),
('AU', 'Australia', 'AUD', true),
('AT', 'Austria', 'EUR', true),
('AZ', 'Azerbaijan', 'AZN', true),
('BH', 'Bahrain', 'BHD', true),
('BD', 'Bangladesh', 'BDT', true),
('BY', 'Belarus', 'BYN', true),
('BE', 'Belgium', 'EUR', true),
('BZ', 'Belize', 'BZD', true),
('BJ', 'Benin', 'XOF', true),
('BT', 'Bhutan', 'BTN', true),
('BO', 'Bolivia', 'BOB', true),
('BA', 'Bosnia and Herzegovina', 'BAM', true),
('BW', 'Botswana', 'BWP', true),
('BR', 'Brazil', 'BRL', true),
('BN', 'Brunei', 'BND', true),
('BG', 'Bulgaria', 'BGN', true),
('BF', 'Burkina Faso', 'XOF', true),
('BI', 'Burundi', 'BIF', true),
('KH', 'Cambodia', 'KHR', true),
('CM', 'Cameroon', 'XAF', true),
('CA', 'Canada', 'CAD', true),
('CV', 'Cape Verde', 'CVE', true),
('CF', 'Central African Republic', 'XAF', true),
('TD', 'Chad', 'XAF', true),
('CL', 'Chile', 'CLP', true),
('CN', 'China', 'CNY', true),
('CO', 'Colombia', 'COP', true),
('KM', 'Comoros', 'KMF', true),
('CG', 'Congo', 'XAF', true),
('CD', 'Congo (Democratic Republic)', 'CDF', true),
('CR', 'Costa Rica', 'CRC', true),
('CI', 'Côte d''Ivoire', 'XOF', true),
('HR', 'Croatia', 'HRK', true),
('CU', 'Cuba', 'CUP', true),
('CY', 'Cyprus', 'EUR', true),
('CZ', 'Czech Republic', 'CZK', true),
('DK', 'Denmark', 'DKK', true),
('DJ', 'Djibouti', 'DJF', true),
('DM', 'Dominica', 'XCD', true),
('DO', 'Dominican Republic', 'DOP', true),
('EC', 'Ecuador', 'USD', true),
('EG', 'Egypt', 'EGP', true),
('SV', 'El Salvador', 'USD', true),
('GQ', 'Equatorial Guinea', 'XAF', true),
('ER', 'Eritrea', 'ERN', true),
('EE', 'Estonia', 'EUR', true),
('SZ', 'Eswatini', 'SZL', true),
('ET', 'Ethiopia', 'ETB', true),
('FJ', 'Fiji', 'FJD', true),
('FI', 'Finland', 'EUR', true),
('FR', 'France', 'EUR', true),
('GA', 'Gabon', 'XAF', true),
('GM', 'Gambia', 'GMD', true),
('GE', 'Georgia', 'GEL', true),
('DE', 'Germany', 'EUR', true),
('GH', 'Ghana', 'GHS', true),
('GR', 'Greece', 'EUR', true),
('GD', 'Grenada', 'XCD', true),
('GT', 'Guatemala', 'GTQ', true),
('GN', 'Guinea', 'GNF', true),
('GW', 'Guinea-Bissau', 'XOF', true),
('GY', 'Guyana', 'GYD', true),
('HT', 'Haiti', 'HTG', true),
('HN', 'Honduras', 'HNL', true),
('HU', 'Hungary', 'HUF', true),
('IS', 'Iceland', 'ISK', true),
('IN', 'India', 'INR', true),
('ID', 'Indonesia', 'IDR', true),
('IR', 'Iran', 'IRR', true),
('IQ', 'Iraq', 'IQD', true),
('IE', 'Ireland', 'EUR', true),
('IL', 'Israel', 'ILS', true),
('IT', 'Italy', 'EUR', true),
('JM', 'Jamaica', 'JMD', true),
('JP', 'Japan', 'JPY', true),
('JO', 'Jordan', 'JOD', true),
('KZ', 'Kazakhstan', 'KZT', true),
('KE', 'Kenya', 'KES', true),
('KI', 'Kiribati', 'AUD', true),
('KP', 'Korea (North)', 'KPW', true),
('KR', 'Korea (South)', 'KRW', true),
('KW', 'Kuwait', 'KWD', true),
('KG', 'Kyrgyzstan', 'KGS', true),
('LA', 'Laos', 'LAK', true),
('LV', 'Latvia', 'EUR', true),
('LB', 'Lebanon', 'LBP', true),
('LS', 'Lesotho', 'LSL', true),
('LR', 'Liberia', 'LRD', true),
('LY', 'Libya', 'LYD', true),
('LI', 'Liechtenstein', 'CHF', true),
('LT', 'Lithuania', 'EUR', true),
('LU', 'Luxembourg', 'EUR', true),
('MG', 'Madagascar', 'MGA', true),
('MW', 'Malawi', 'MWK', true),
('MY', 'Malaysia', 'MYR', true),
('MV', 'Maldives', 'MVR', true),
('ML', 'Mali', 'XOF', true),
('MT', 'Malta', 'EUR', true),
('MH', 'Marshall Islands', 'USD', true),
('MR', 'Mauritania', 'MRU', true),
('MU', 'Mauritius', 'MUR', true),
('MX', 'Mexico', 'MXN', true),
('FM', 'Micronesia', 'USD', true),
('MD', 'Moldova', 'MDL', true),
('MC', 'Monaco', 'EUR', true),
('MN', 'Mongolia', 'MNT', true),
('ME', 'Montenegro', 'EUR', true),
('MA', 'Morocco', 'MAD', true),
('MZ', 'Mozambique', 'MZN', true),
('MM', 'Myanmar', 'MMK', true),
('NA', 'Namibia', 'NAD', true),
('NR', 'Nauru', 'AUD', true),
('NP', 'Nepal', 'NPR', true),
('NL', 'Netherlands', 'EUR', true),
('NZ', 'New Zealand', 'NZD', true),
('NI', 'Nicaragua', 'NIO', true),
('NE', 'Niger', 'XOF', true),
('NG', 'Nigeria', 'NGN', true),
('MK', 'North Macedonia', 'MKD', true),
('NO', 'Norway', 'NOK', true),
('OM', 'Oman', 'OMR', true),
('PK', 'Pakistan', 'PKR', true),
('PW', 'Palau', 'USD', true),
('PS', 'Palestine', 'ILS', true),
('PA', 'Panama', 'PAB', true),
('PG', 'Papua New Guinea', 'PGK', true),
('PY', 'Paraguay', 'PYG', true),
('PE', 'Peru', 'PEN', true),
('PH', 'Philippines', 'PHP', true),
('PL', 'Poland', 'PLN', true),
('PT', 'Portugal', 'EUR', true),
('QA', 'Qatar', 'QAR', true),
('RO', 'Romania', 'RON', true),
('RU', 'Russia', 'RUB', true),
('RW', 'Rwanda', 'RWF', true),
('KN', 'Saint Kitts and Nevis', 'XCD', true),
('LC', 'Saint Lucia', 'XCD', true),
('VC', 'Saint Vincent and the Grenadines', 'XCD', true),
('WS', 'Samoa', 'WST', true),
('SM', 'San Marino', 'EUR', true),
('ST', 'São Tomé and Príncipe', 'STN', true),
('SA', 'Saudi Arabia', 'SAR', true),
('SN', 'Senegal', 'XOF', true),
('RS', 'Serbia', 'RSD', true),
('SC', 'Seychelles', 'SCR', true),
('SL', 'Sierra Leone', 'SLL', true),
('SG', 'Singapore', 'SGD', true),
('SK', 'Slovakia', 'EUR', true),
('SI', 'Slovenia', 'EUR', true),
('SB', 'Solomon Islands', 'SBD', true),
('SO', 'Somalia', 'SOS', true),
('ZA', 'South Africa', 'ZAR', true),
('SS', 'South Sudan', 'SSP', true),
('ES', 'Spain', 'EUR', true),
('LK', 'Sri Lanka', 'LKR', true),
('SD', 'Sudan', 'SDG', true),
('SR', 'Suriname', 'SRD', true),
('SE', 'Sweden', 'SEK', true),
('CH', 'Switzerland', 'CHF', true),
('SY', 'Syria', 'SYP', true),
('TW', 'Taiwan', 'TWD', true),
('TJ', 'Tajikistan', 'TJS', true),
('TZ', 'Tanzania', 'TZS', true),
('TH', 'Thailand', 'THB', true),
('TL', 'Timor-Leste', 'USD', true),
('TG', 'Togo', 'XOF', true),
('TO', 'Tonga', 'TOP', true),
('TT', 'Trinidad and Tobago', 'TTD', true),
('TN', 'Tunisia', 'TND', true),
('TR', 'Turkey', 'TRY', true),
('TM', 'Turkmenistan', 'TMT', true),
('TV', 'Tuvalu', 'AUD', true),
('UG', 'Uganda', 'UGX', true),
('UA', 'Ukraine', 'UAH', true),
('AE', 'United Arab Emirates', 'AED', true),
('GB', 'United Kingdom', 'GBP', true),
('US', 'United States', 'USD', true),
('UY', 'Uruguay', 'UYU', true),
('UZ', 'Uzbekistan', 'UZS', true),
('VU', 'Vanuatu', 'VUV', true),
('VA', 'Vatican City', 'EUR', true),
('VE', 'Venezuela', 'VES', true),
('VN', 'Vietnam', 'VND', true),
('YE', 'Yemen', 'YER', true),
('ZM', 'Zambia', 'ZMW', true),
('ZW', 'Zimbabwe', 'ZWL', true),

-- Additional territories and dependencies
('AD', 'Andorra', 'EUR', true),
('AI', 'Anguilla', 'XCD', true),
('AG', 'Antigua and Barbuda', 'XCD', true),
('FO', 'Faroe Islands', 'DKK', true),
('GF', 'French Guiana', 'EUR', true),
('PF', 'French Polynesia', 'XPF', true),
('TF', 'French Southern Territories', 'EUR', true),
('GI', 'Gibraltar', 'GIP', true),
('GL', 'Greenland', 'DKK', true),
('GP', 'Guadeloupe', 'EUR', true),
('GU', 'Guam', 'USD', true),
('GG', 'Guernsey', 'GBP', true),
('HM', 'Heard Island and McDonald Islands', 'AUD', true),
('HK', 'Hong Kong', 'HKD', true),
('IM', 'Isle of Man', 'GBP', true),
('JE', 'Jersey', 'GBP', true),
('MQ', 'Martinique', 'EUR', true),
('YT', 'Mayotte', 'EUR', true)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    currency = EXCLUDED.currency,
    "isActive" = EXCLUDED."isActive";

-- Demo User
INSERT INTO users (id, email, "passwordHash", "firstName", "lastName", isresident, "isOnboardingCompleted")
VALUES ('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'testuser@paykey.com', 'SecurePass123!', 'Test', 'User', true, true);

-- Pay Periods for Demo User
INSERT INTO pay_periods ("userId", name, "startDate", "endDate", frequency, status) VALUES
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'January 2024', '2024-01-01', '2024-01-31', 'MONTHLY', 'CLOSED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'February 2024', '2024-02-01', '2024-02-29', 'MONTHLY', 'CLOSED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'March 2024', '2024-03-01', '2024-03-31', 'MONTHLY', 'CLOSED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'April 2024', '2024-04-01', '2024-04-30', 'MONTHLY', 'CLOSED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'May 2024', '2024-05-01', '2024-05-31', 'MONTHLY', 'OPEN');

-- Demo Workers (Enhanced with job titles, allowances, and payment details)
INSERT INTO workers (
    "userId", name, "phoneNumber", "salaryGross", "startDate", 
    "employmentType", "isActive", "paymentFrequency", "jobTitle", 
    "hourlyRate", "housingAllowance", "transportAllowance", "mpesaNumber"
) VALUES 
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Jane Doe', 
    '+254700123456', 
    15000.00, 
    '2024-01-15', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Housekeeper', 
    865.38, 
    0, 
    0, 
    '+254700123456'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Kamau Wanjiku', 
    '+254700234567', 
    120000.00, 
    '2024-02-01', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'House Manager', 
    6923.08, 
    15000, 
    8000, 
    '+254700234567'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Ochieng Achieng', 
    '+254700345678', 
    120000.00, 
    '2024-03-01', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Nanny', 
    6923.08, 
    12000, 
    5000, 
    '+254700345678'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Kiprotich Ngeny', 
    '+254700456789', 
    10000.00, 
    '2024-04-01', 
    'HOURLY', 
    true, 
    'WEEKLY', 
    'Gardener', 
    200.00, 
    0, 
    0, 
    '+254700456789'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Mwangi Kamau', 
    '+254700567890', 
    120000.00, 
    '2024-05-01', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Cook', 
    6923.08, 
    10000, 
    6000, 
    '+254700567890'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Peter Otieno', 
    '+254700678901', 
    80000.00, 
    '2024-01-20', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Driver', 
    4615.38, 
    8000, 
    12000, 
    '+254700678901'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'David Kipchoge', 
    '+254700789012', 
    60000.00, 
    '2024-02-10', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Security Guard', 
    3461.54, 
    5000, 
    3000,
    '+254700789012'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Grace Akinyi', 
    '+254700890123', 
    45000.00, 
    '2024-03-05', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Laundry Assistant', 
    2596.15, 
    0, 
    2000, 
    '+254700890123'
)
ON CONFLICT (name, "userId") DO NOTHING;

-- Subscription Data (PLATINUM tier)
INSERT INTO subscriptions (
    "userId", tier, status, amount, currency, "startDate", "endDate", "nextBillingDate", 
    "stripeSubscriptionId", "stripePriceId", notes
) VALUES 
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'PLATINUM',
    'ACTIVE',
    7200.00,
    'KES',
    '2024-01-01'::timestamptz,
    '2025-01-01'::timestamptz,
    '2024-12-01'::timestamptz,
    'sub_demo_platinum_123456789',
    'price_demo_platinum_123456789',
    'Demo user with PLATINUM subscription for testing'
)
ON CONFLICT ("userId", tier) DO UPDATE SET
    status = EXCLUDED.status,
    amount = EXCLUDED.amount,
    "startDate" = EXCLUDED."startDate",
    "endDate" = EXCLUDED."endDate",
    "nextBillingDate" = EXCLUDED."nextBillingDate",
    notes = EXCLUDED.notes;

-- Subscription Payment History
-- Removed INSERT INTO subscription_payment_history for debugging

-- Payroll Records
INSERT INTO payroll_records ("userId", "workerId", "periodStart", "periodEnd", "grossSalary", "netSalary", "taxAmount", "paymentStatus", "paymentMethod", "paymentDate")
SELECT 
    w."userId",
    w.id,
    pp."startDate",
    pp."endDate",
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 120000 / 2
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 15000 / 2
        ELSE 10000
    END,
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 95000 / 2
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 12500 / 2
        ELSE 8000
    END,
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 25000 / 2
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 2500 / 2
        ELSE 2000
    END,
    'paid',
    'mpesa',
    pp."endDate" + interval '3 days'
FROM workers w
CROSS JOIN pay_periods pp
WHERE w."userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'
AND pp."userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';

-- Update Pay Period Totals
UPDATE pay_periods 
SET 
    "totalGrossAmount" = (
        SELECT COALESCE(SUM("grossSalary"), 0)
        FROM payroll_records pr 
        WHERE pr."periodStart" = pay_periods."startDate" 
        AND pr."periodEnd" = pay_periods."endDate"
    ),
    "totalNetAmount" = (
        SELECT COALESCE(SUM("netSalary"), 0)
        FROM payroll_records pr 
        WHERE pr."periodStart" = pay_periods."startDate" 
        AND pr."periodEnd" = pay_periods."endDate"
    ),
    "totalTaxAmount" = (
        SELECT COALESCE(SUM("taxAmount"), 0)
        FROM payroll_records pr 
        WHERE pr."periodStart" = pay_periods."startDate" 
        AND pr."periodEnd" = pay_periods."endDate"
    ),
    "totalWorkers" = (
        SELECT COUNT(*)
        FROM payroll_records pr 
        WHERE pr."periodStart" = pay_periods."startDate" 
        AND pr."periodEnd" = pay_periods."endDate"
    ),
    "processedWorkers" = (
        SELECT COUNT(*)
        FROM payroll_records pr 
        WHERE pr."periodStart" = pay_periods."startDate" 
        AND pr."periodEnd" = pay_periods."endDate"
        AND pr."paymentStatus" = 'paid'
    )
WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';

-- Tax Payment Records
-- Removed INSERT INTO tax_payments for debugging

-- Tax Submissions (linked to pay periods)
-- Removed INSERT INTO tax_submissions for debugging
