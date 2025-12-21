-- First drop the types if they exist (to avoid conflicts)
DROP TYPE IF EXISTS tax_configs_tax_type_enum;
DROP TYPE IF EXISTS tax_configs_rate_type_enum;

-- Create types
CREATE TYPE tax_configs_tax_type_enum AS ENUM('PAYE', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY');
CREATE TYPE tax_configs_rate_type_enum AS ENUM('PERCENTAGE', 'GRADUATED', 'TIERED');

-- Drop table if it exists
DROP TABLE IF EXISTS tax_configs;

-- Create tax_configs table
CREATE TABLE tax_configs (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "taxType" tax_configs_tax_type_enum NOT NULL,
    "rateType" tax_configs_rate_type_enum NOT NULL,
    "effectiveFrom" date NOT NULL,
    "effectiveTo" date,
    "configuration" jsonb NOT NULL,
    "paymentDeadline" character varying NOT NULL DEFAULT '9th of following month',
    "isActive" boolean NOT NULL DEFAULT true,
    "notes" text,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT "PK_90f8c1c6e04d3d8e8e8b2b2b2b" PRIMARY KEY ("id")
);

-- Create indexes
CREATE INDEX "IDX_1c2c3c4c5c6c7c8c9c9c9c9c9c" ON "tax_configs" ("taxType");
CREATE INDEX "IDX_2d3d4d5d6d7d8d9d9d9d9d9d9d" ON "tax_configs" ("effectiveFrom", "effectiveTo");