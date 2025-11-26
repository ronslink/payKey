import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateTaxPaymentsTable1732469012000 implements MigrationInterface {
    name = 'CreateTaxPaymentsTable1732469012000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."tax_payments_tax_type_enum" AS ENUM('PAYE', 'NSSF_TIER1', 'NSSF_TIER2', 'NHIF', 'HOUSING_LEVY', 'SHIF')`);
        await queryRunner.query(`CREATE TYPE "public"."tax_payments_payment_method_enum" AS ENUM('MPESA', 'BANK')`);
        await queryRunner.query(`CREATE TYPE "public"."tax_payments_status_enum" AS ENUM('PENDING', 'PAID', 'OVERDUE')`);
        await queryRunner.query(`CREATE TABLE "tax_payments" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "taxType" "public"."tax_payments_tax_type_enum" NOT NULL, "paymentYear" integer NOT NULL, "paymentMonth" integer NOT NULL, "amount" numeric(12,2) NOT NULL DEFAULT 0, "paymentDate" date, "paymentMethod" "public"."tax_payments_payment_method_enum", "receiptNumber" character varying, "status" "public"."tax_payments_status_enum" NOT NULL DEFAULT 'PENDING', "notes" text, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_90f8c1c6e04d3d8e8e8b2b2b2b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_6cc3c9b8b3d5c3c3c3c3c3c3c" ON "tax_payments" ("userId") `);
        await queryRunner.query(`ALTER TABLE "tax_payments" ADD CONSTRAINT "FK_8c8c8c8c8c8c8c8c8c8c8c8c8" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "tax_payments" DROP CONSTRAINT "FK_8c8c8c8c8c8c8c8c8c8c8c8c"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_6cc3c9b8b3d5c3c3c3c3c3c3c3c"`);
        await queryRunner.query(`DROP TABLE "tax_payments"`);
        await queryRunner.query(`DROP TYPE "public"."tax_payments_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."tax_payments_payment_method_enum"`);
        await queryRunner.query(`DROP TYPE "public"."tax_payments_tax_type_enum"`);
    }

}