import { MigrationInterface, QueryRunner } from "typeorm";

export class AddWalletBalance1734789600000 implements MigrationInterface {
    name = 'AddWalletBalance1734789600000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Add walletBalance column to users table with default 0
        await queryRunner.query(`
            ALTER TABLE "users" 
            ADD COLUMN IF NOT EXISTS "walletBalance" decimal(12,2) DEFAULT 0;
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE "users" DROP COLUMN IF EXISTS "walletBalance";
        `);
    }
}
