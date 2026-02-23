-- Create TaxType enum if not exists
DO $$ BEGIN
    CREATE TYPE taxtype AS ENUM ('PAYE', 'NHIF', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create RateType enum if not exists
DO $$ BEGIN
    CREATE TYPE ratetype AS ENUM ('PERCENTAGE', 'GRADUATED', 'TIERED', 'BANDED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
