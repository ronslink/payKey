"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateAccountMappingsTable1735200000003 = void 0;
class CreateAccountMappingsTable1735200000003 {
    name = 'CreateAccountMappingsTable1735200000003';
    async up(queryRunner) {
        await queryRunner.query(`CREATE TYPE "public"."account_mappings_mapping_type_enum" AS ENUM('EXPENSE_ACCOUNT', 'ASSET_ACCOUNT', 'LIABILITY_ACCOUNT', 'REVENUE_ACCOUNT', 'COST_CENTER')`);
        await queryRunner.query(`CREATE TABLE "account_mappings" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "userId" uuid NOT NULL,
        "name" varchar NOT NULL,
        "mappingType" "public"."account_mappings_mapping_type_enum" NOT NULL,
        "accountCode" varchar NOT NULL,
        "description" text,
        "isActive" boolean DEFAULT true,
        "parentAccountId" uuid,
        "balance" decimal(15,2) DEFAULT 0,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_account_mappings_id" PRIMARY KEY ("id")
      )`);
        await queryRunner.query(`CREATE INDEX "idx_account_mappings_userId" ON "account_mappings" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_account_mappings_mappingType" ON "account_mappings" ("mappingType")`);
        await queryRunner.query(`CREATE INDEX "idx_account_mappings_accountCode" ON "account_mappings" ("accountCode")`);
        await queryRunner.query(`CREATE INDEX "idx_account_mappings_parentAccountId" ON "account_mappings" ("parentAccountId")`);
        await queryRunner.query(`ALTER TABLE "account_mappings" ADD CONSTRAINT "FK_account_mappings_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`);
        await queryRunner.query(`ALTER TABLE "account_mappings" ADD CONSTRAINT "FK_account_mappings_parentAccountId" FOREIGN KEY ("parentAccountId") REFERENCES "account_mappings"("id") ON DELETE SET NULL`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "account_mappings" DROP CONSTRAINT "FK_account_mappings_parentAccountId"`);
        await queryRunner.query(`ALTER TABLE "account_mappings" DROP CONSTRAINT "FK_account_mappings_userId"`);
        await queryRunner.query(`DROP INDEX "idx_account_mappings_parentAccountId"`);
        await queryRunner.query(`DROP INDEX "idx_account_mappings_accountCode"`);
        await queryRunner.query(`DROP INDEX "idx_account_mappings_mappingType"`);
        await queryRunner.query(`DROP INDEX "idx_account_mappings_userId"`);
        await queryRunner.query(`DROP TABLE "account_mappings"`);
        await queryRunner.query(`DROP TYPE "public"."account_mappings_mapping_type_enum"`);
    }
}
exports.CreateAccountMappingsTable1735200000003 = CreateAccountMappingsTable1735200000003;
//# sourceMappingURL=1735200000003-create-account-mappings-table.js.map