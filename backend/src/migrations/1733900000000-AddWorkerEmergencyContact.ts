import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWorkerEmergencyContact1733900000000
    implements MigrationInterface {
    name = 'AddWorkerEmergencyContact1733900000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "workers" ADD "emergencyContactName" character varying`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" ADD "emergencyContactPhone" character varying`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" ADD "emergencyContactRelationship" character varying`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "workers" DROP COLUMN "emergencyContactRelationship"`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" DROP COLUMN "emergencyContactPhone"`,
        );
        await queryRunner.query(
            `ALTER TABLE "workers" DROP COLUMN "emergencyContactName"`,
        );
    }
}
