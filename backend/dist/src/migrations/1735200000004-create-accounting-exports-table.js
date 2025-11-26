"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateAccountingExportsTable1735200000004 = void 0;
class CreateAccountingExportsTable1735200000004 {
    name = 'CreateAccountingExportsTable1735200000004';
    async up(queryRunner) {
        await queryRunner.query(`CREATE TYPE "public"."accounting_exports_export_type_enum" AS ENUM('PAYROLL_SUMMARY', 'TAX_REPORT', 'COST_ANALYSIS', 'LEDGER_EXPORT', 'BALANCE_SHEET', 'P&L_STATEMENT')`);
        await queryRunner.query(`CREATE TYPE "public"."accounting_exports_status_enum" AS ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')`);
        await queryRunner.query(`CREATE TYPE "public"."accounting_exports_format_enum" AS ENUM('CSV', 'EXCEL', 'PDF', 'JSON', 'XML')`);
        await queryRunner.query(`CREATE TABLE "accounting_exports" (
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
      )`);
        await queryRunner.query(`CREATE INDEX "idx_accounting_exports_userId" ON "accounting_exports" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_accounting_exports_status" ON "accounting_exports" ("status")`);
        await queryRunner.query(`CREATE INDEX "idx_accounting_exports_exportType" ON "accounting_exports" ("exportType")`);
        await queryRunner.query(`CREATE INDEX "idx_accounting_exports_createdAt" ON "accounting_exports" ("createdAt")`);
        await queryRunner.query(`ALTER TABLE "accounting_exports" ADD CONSTRAINT "FK_accounting_exports_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "accounting_exports" DROP CONSTRAINT "FK_accounting_exports_userId"`);
        await queryRunner.query(`DROP INDEX "idx_accounting_exports_createdAt"`);
        await queryRunner.query(`DROP INDEX "idx_accounting_exports_exportType"`);
        await queryRunner.query(`DROP INDEX "idx_accounting_exports_status"`);
        await queryRunner.query(`DROP INDEX "idx_accounting_exports_userId"`);
        await queryRunner.query(`DROP TABLE "accounting_exports"`);
        await queryRunner.query(`DROP TYPE "public"."accounting_exports_format_enum"`);
        await queryRunner.query(`DROP TYPE "public"."accounting_exports_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."accounting_exports_export_type_enum"`);
    }
}
exports.CreateAccountingExportsTable1735200000004 = CreateAccountingExportsTable1735200000004;
//# sourceMappingURL=1735200000004-create-accounting-exports-table.js.map