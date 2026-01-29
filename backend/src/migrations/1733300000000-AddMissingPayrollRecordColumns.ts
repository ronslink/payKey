import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMissingPayrollRecordColumns1733300000000 implements MigrationInterface {
  name = 'AddMissingPayrollRecordColumns1733300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "payroll_records" 
      ADD COLUMN IF NOT EXISTS "bonuses" numeric(10,2) NOT NULL DEFAULT '0',
      ADD COLUMN IF NOT EXISTS "otherEarnings" numeric(10,2) NOT NULL DEFAULT '0',
      ADD COLUMN IF NOT EXISTS "otherDeductions" numeric(10,2) NOT NULL DEFAULT '0',
      ADD COLUMN IF NOT EXISTS "status" character varying NOT NULL DEFAULT 'draft',
      ADD COLUMN IF NOT EXISTS "finalizedAt" TIMESTAMP
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "payroll_records" 
      DROP COLUMN "bonuses",
      DROP COLUMN "otherEarnings",
      DROP COLUMN "otherDeductions",
      DROP COLUMN "status",
      DROP COLUMN "finalizedAt"
    `);
  }
}
