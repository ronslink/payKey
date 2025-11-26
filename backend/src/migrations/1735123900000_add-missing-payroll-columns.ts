import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMissingPayrollColumns1735123900000
  implements MigrationInterface
{
  name = 'AddMissingPayrollColumns1735123900000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD COLUMN "payPeriodId" uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD COLUMN "bonuses" decimal(10,2) DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD COLUMN "otherEarnings" decimal(10,2) DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD COLUMN "otherDeductions" decimal(10,2) DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD COLUMN "status" varchar DEFAULT 'draft'`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD COLUMN "finalizedAt" TIMESTAMP WITH TIME ZONE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP COLUMN "finalizedAt"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP COLUMN "status"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP COLUMN "otherDeductions"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP COLUMN "otherEarnings"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP COLUMN "bonuses"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP COLUMN "payPeriodId"`,
    );
  }
}
