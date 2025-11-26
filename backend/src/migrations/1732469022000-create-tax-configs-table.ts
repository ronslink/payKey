import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateTaxConfigsTable1732469022000 implements MigrationInterface {
    name = 'CreateTaxConfigsTable1732469022000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."tax_configs_tax_type_enum" AS ENUM('PAYE', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY')`);
        await queryRunner.query(`CREATE TYPE "public"."tax_configs_rate_type_enum" AS ENUM('PERCENTAGE', 'GRADUATED', 'TIERED')`);
        await queryRunner.query(`CREATE TABLE "tax_configs" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "taxType" "public"."tax_configs_tax_type_enum" NOT NULL, "rateType" "public"."tax_configs_rate_type_enum" NOT NULL, "effectiveFrom" date NOT NULL, "effectiveTo" date, "configuration" jsonb NOT NULL, "paymentDeadline" character varying NOT NULL DEFAULT '9th of following month', "isActive" boolean NOT NULL DEFAULT true, "notes" text, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_90f8c1c6e04d3d8e8e8b2b2b2b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_1c2c3c4c5c6c7c8c9c9c9c9c9c" ON "tax_configs" ("taxType") `);
        await queryRunner.query(`CREATE INDEX "IDX_2d3d4d5d6d7d8d9d9d9d9d9d9d" ON "tax_configs" ("effectiveFrom", "effectiveTo") `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_2d3d4d5d6d7d8d9d9d9d9d9d9d"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_1c2c3c4c5c6c7c8c9c9c9c9c9c"`);
        await queryRunner.query(`DROP TABLE "tax_configs"`);
        await queryRunner.query(`DROP TYPE "public"."tax_configs_rate_type_enum"`);
        await queryRunner.query(`DROP TYPE "public"."tax_configs_tax_type_enum"`);
    }

}