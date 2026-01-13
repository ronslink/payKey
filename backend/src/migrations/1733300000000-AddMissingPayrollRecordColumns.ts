import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMissingPayrollRecordColumns1733300000000 implements MigrationInterface {
  name = 'AddMissingPayrollRecordColumns1733300000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "payroll_records" 
      ADD "bonuses" numeric(10,2) NOT NULL DEFAULT '0',
      ADD "otherEarnings" numeric(10,2) NOT NULL DEFAULT '0',
      ADD "otherDeductions" numeric(10,2) NOT NULL DEFAULT '0',
      ADD "status" character varying NOT NULL DEFAULT 'draft',
      ADD "finalizedAt" TIMESTAMP
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
