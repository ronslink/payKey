import { MigrationInterface, QueryRunner } from "typeorm";

export class FixWorkersTerminationidDatatype1735200000006 implements MigrationInterface {
    name = 'FixWorkersTerminationidDatatype1735200000006'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // First, update any existing data in terminationId column to be proper UUID format
        await queryRunner.query(`
            UPDATE workers 
            SET terminationId = NULL 
            WHERE terminationId IS NOT NULL AND terminationId !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        `);

        // Alter the column type from VARCHAR to UUID
        await queryRunner.query(`
            ALTER TABLE workers 
            ALTER COLUMN terminationId TYPE UUID USING terminationId::UUID
        `);

        // Add constraint to ensure it's a valid UUID
        await queryRunner.query(`
            ALTER TABLE workers 
            ADD CONSTRAINT workers_terminationid_uuid_check 
            CHECK (terminationId IS NULL OR terminationId ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Revert back to VARCHAR
        await queryRunner.query(`
            ALTER TABLE workers 
            DROP CONSTRAINT IF EXISTS workers_terminationid_uuid_check
        `);

        await queryRunner.query(`
            ALTER TABLE workers 
            ALTER COLUMN terminationId TYPE VARCHAR(255)
        `);
    }

}