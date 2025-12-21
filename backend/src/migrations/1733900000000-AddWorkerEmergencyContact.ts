import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWorkerEmergencyContact1733900000000
    implements MigrationInterface {
    name = 'AddWorkerEmergencyContact1733900000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Use IF NOT EXISTS for idempotency
        await queryRunner.query(
            `ALTER TABLE "workers" ADD COLUMN IF NOT EXISTS "emergencyContactName" character varying`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" ADD COLUMN IF NOT EXISTS "emergencyContactPhone" character varying`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" ADD COLUMN IF NOT EXISTS "emergencyContactRelationship" character varying`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "workers" DROP COLUMN IF EXISTS "emergencyContactRelationship"`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" DROP COLUMN IF EXISTS "emergencyContactPhone"`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" DROP COLUMN IF EXISTS "emergencyContactName"`,
        );
    }
}
