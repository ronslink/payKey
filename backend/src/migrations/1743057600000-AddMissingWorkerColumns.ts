import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMissingWorkerColumns1743057600000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "workers"
        ADD COLUMN IF NOT EXISTS "pensionContribution" decimal(12,2) DEFAULT 0 NOT NULL,
        ADD COLUMN IF NOT EXISTS "mortgageInterest" decimal(12,2) DEFAULT 0 NOT NULL,
        ADD COLUMN IF NOT EXISTS "hospContribution" decimal(12,2) DEFAULT 0 NOT NULL,
        ADD COLUMN IF NOT EXISTS "lifeInsurancePremium" decimal(12,2) DEFAULT 0 NOT NULL,
        ADD COLUMN IF NOT EXISTS "nonCashBenefits" decimal(12,2) DEFAULT 0 NOT NULL,
        ADD COLUMN IF NOT EXISTS "nonTaxableAllowance" decimal(12,2) DEFAULT 0 NOT NULL,
        ADD COLUMN IF NOT EXISTS "hasDisabilityExemption" boolean DEFAULT false NOT NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "workers"
        DROP COLUMN IF EXISTS "pensionContribution",
        DROP COLUMN IF EXISTS "mortgageInterest",
        DROP COLUMN IF EXISTS "hospContribution",
        DROP COLUMN IF EXISTS "lifeInsurancePremium",
        DROP COLUMN IF EXISTS "nonCashBenefits",
        DROP COLUMN IF EXISTS "nonTaxableAllowance",
        DROP COLUMN IF EXISTS "hasDisabilityExemption";
    `);
  }
}
