import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAccountMappingsTable1735200000003
  implements MigrationInterface
{
  name = 'CreateAccountMappingsTable1735200000003';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create mapping_type enum
    await queryRunner.query(
      `CREATE TYPE "public"."account_mappings_mapping_type_enum" AS ENUM('EXPENSE_ACCOUNT', 'ASSET_ACCOUNT', 'LIABILITY_ACCOUNT', 'REVENUE_ACCOUNT', 'COST_CENTER')`,
    );

    // Create account_mappings table
    await queryRunner.query(
      `CREATE TABLE "account_mappings" (
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
      )`,
    );

    // Create indexes
    await queryRunner.query(
      `CREATE INDEX "idx_account_mappings_userId" ON "account_mappings" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_account_mappings_mappingType" ON "account_mappings" ("mappingType")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_account_mappings_accountCode" ON "account_mappings" ("accountCode")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_account_mappings_parentAccountId" ON "account_mappings" ("parentAccountId")`,
    );

    // Add foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "account_mappings" ADD CONSTRAINT "FK_account_mappings_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "account_mappings" ADD CONSTRAINT "FK_account_mappings_parentAccountId" FOREIGN KEY ("parentAccountId") REFERENCES "account_mappings"("id") ON DELETE SET NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "account_mappings" DROP CONSTRAINT "FK_account_mappings_parentAccountId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "account_mappings" DROP CONSTRAINT "FK_account_mappings_userId"`,
    );

    // Drop indexes
    await queryRunner.query(
      `DROP INDEX "idx_account_mappings_parentAccountId"`,
    );
    await queryRunner.query(`DROP INDEX "idx_account_mappings_accountCode"`);
    await queryRunner.query(`DROP INDEX "idx_account_mappings_mappingType"`);
    await queryRunner.query(`DROP INDEX "idx_account_mappings_userId"`);

    // Drop table
    await queryRunner.query(`DROP TABLE "account_mappings"`);

    // Drop enum
    await queryRunner.query(
      `DROP TYPE "public"."account_mappings_mapping_type_enum"`,
    );
  }
}
