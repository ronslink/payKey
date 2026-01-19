import { MigrationInterface, QueryRunner } from "typeorm";

export class AddIntaSendWalletId1768850446161 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" ADD "intasend_wallet_id" character varying`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_intasend_wallet_id" UNIQUE ("intasend_wallet_id")`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_intasend_wallet_id"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "intasend_wallet_id"`);
    }

}
