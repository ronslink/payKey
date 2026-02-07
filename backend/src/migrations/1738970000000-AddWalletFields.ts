import { MigrationInterface, QueryRunner } from "typeorm";

export class AddWalletFields1738970000000 implements MigrationInterface {
    name = 'AddWalletFields1738970000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Add intasend_wallet_id to users
        // Check if column exists first to avoid errors if running on a synced DB
        const hasUserCol = await queryRunner.hasColumn("users", "intasend_wallet_id");
        if (!hasUserCol) {
            await queryRunner.query(`ALTER TABLE "users" ADD "intasend_wallet_id" character varying`);
            await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_intasend_wallet_id" UNIQUE ("intasend_wallet_id")`);
        }

        // Add walletId to transactions
        const hasTxCol = await queryRunner.hasColumn("transactions", "walletId");
        if (!hasTxCol) {
            await queryRunner.query(`ALTER TABLE "transactions" ADD "walletId" character varying`);
        }
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        const hasTxCol = await queryRunner.hasColumn("transactions", "walletId");
        if (hasTxCol) {
            await queryRunner.query(`ALTER TABLE "transactions" DROP COLUMN "walletId"`);
        }

        const hasUserCol = await queryRunner.hasColumn("users", "intasend_wallet_id");
        if (hasUserCol) {
            await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_intasend_wallet_id"`);
            await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "intasend_wallet_id"`);
        }
    }
}
