import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAccountingTables1733220000000 implements MigrationInterface {
  name = 'CreateAccountingTables1733220000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "public"."account_mappings_category_enum" AS ENUM('SALARY_EXPENSE', 'PAYE_LIABILITY', 'NSSF_LIABILITY', 'NHIF_LIABILITY', 'HOUSING_LEVY_LIABILITY', 'CASH_BANK')
    `);
    await queryRunner.query(`
      CREATE TABLE "account_mappings" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "category" "public"."account_mappings_category_enum" NOT NULL,
        "accountCode" character varying NOT NULL,
        "accountName" character varying NOT NULL,
        "description" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_account_mappings_id" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TYPE "public"."accounting_exports_format_enum" AS ENUM('CSV', 'EXCEL', 'QUICKBOOKS', 'XERO', 'SAGE')
    `);
    await queryRunner.query(`
      CREATE TYPE "public"."accounting_exports_status_enum" AS ENUM('PENDING', 'COMPLETED', 'FAILED')
    `);
    await queryRunner.query(`
      CREATE TABLE "accounting_exports" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "payPeriodId" uuid NOT NULL,
        "format" "public"."accounting_exports_format_enum" NOT NULL,
        "status" "public"."accounting_exports_status_enum" NOT NULL DEFAULT 'PENDING',
        "filePath" character varying,
        "externalId" character varying,
        "errorMessage" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_accounting_exports_id" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      ALTER TABLE "accounting_exports" 
      ADD CONSTRAINT "FK_accounting_exports_payPeriodId" 
      FOREIGN KEY ("payPeriodId") REFERENCES "pay_periods"("id") ON DELETE NO ACTION ON UPDATE NO ACTION
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "accounting_exports" DROP CONSTRAINT "FK_accounting_exports_payPeriodId"`,
    );
    await queryRunner.query(`DROP TABLE "accounting_exports"`);
    await queryRunner.query(
      `DROP TYPE "public"."accounting_exports_status_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE "public"."accounting_exports_format_enum"`,
    );
    await queryRunner.query(`DROP TABLE "account_mappings"`);
    await queryRunner.query(
      `DROP TYPE "public"."account_mappings_category_enum"`,
    );
  }
}
