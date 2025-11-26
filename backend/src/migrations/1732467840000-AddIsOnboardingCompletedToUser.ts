import { MigrationInterface, QueryRunner } from "typeorm";

export class AddIsOnboardingCompletedToUser1732467840000 implements MigrationInterface {
    name = 'AddIsOnboardingCompletedToUser1732467840000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" ADD "isOnboardingCompleted" boolean NOT NULL DEFAULT false`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "isOnboardingCompleted"`);
    }

}