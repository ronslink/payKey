import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAccountingExportsTable1735200000004
  implements MigrationInterface
{
  name = 'CreateAccountingExportsTable1735200000004';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create export_type enum
    await queryRunner.query(
      `CREATE TYPE "public"."accounting_exports_export_type_enum" AS ENUM('PAYROLL_SUMMARY', 'TAX_REPORT', 'COST_ANALYSIS', 'LEDGER_EXPORT', 'BALANCE_SHEET', 'P&L_STATEMENT')`,
    );

    // Create status enum
    await queryRunner.query(
      `CREATE TYPE "public"."accounting_exports_status_enum" AS ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')`,
    );

    // Create format enum
    await queryRunner.query(
      `CREATE TYPE "public"."accounting_exports_format_enum" AS ENUM('CSV', 'EXCEL', 'PDF', 'JSON', 'XML')`,
    );

    // Create accounting_exports table
    await queryRunner.query(
      `CREATE TABLE "accounting_exports" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "userId" uuid NOT NULL,
        "exportType" "public"."accounting_exports_export_type_enum" NOT NULL,
        "status" "public"."accounting_exports_status_enum" NOT NULL DEFAULT 'PENDING',
        "format" "public"."accounting_exports_format_enum" NOT NULL,
        "startDate" date,
        "endDate" date,
        "fileName" varchar,
        "filePath" varchar,
        "fileSize" bigint,
        "recordCount" integer DEFAULT 0,
        "errorMessage" text,
        "exportSettings" jsonb,
        "completedAt" TIMESTAMP WITH TIME ZONE,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_accounting_exports_id" PRIMARY KEY ("id")
      )`,
    );

    // Create indexes
    await queryRunner.query(
      `CREATE INDEX "idx_accounting_exports_userId" ON "accounting_exports" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_accounting_exports_status" ON "accounting_exports" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_accounting_exports_exportType" ON "accounting_exports" ("exportType")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_accounting_exports_createdAt" ON "accounting_exports" ("createdAt")`,
    );

    // Add foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "accounting_exports" ADD CONSTRAINT "FK_accounting_exports_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "accounting_exports" DROP CONSTRAINT "FK_accounting_exports_userId"`,
    );

    // Drop indexes
    await queryRunner.query(`DROP INDEX "idx_accounting_exports_createdAt"`);
    await queryRunner.query(`DROP INDEX "idx_accounting_exports_exportType"`);
    await queryRunner.query(`DROP INDEX "idx_accounting_exports_status"`);
    await queryRunner.query(`DROP INDEX "idx_accounting_exports_userId"`);

    // Drop table
    await queryRunner.query(`DROP TABLE "accounting_exports"`);

    // Drop enums
    await queryRunner.query(
      `DROP TYPE "public"."accounting_exports_format_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE "public"."accounting_exports_status_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE "public"."accounting_exports_export_type_enum"`,
    );
  }
}
