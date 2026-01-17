import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Creates the worker_documents table
 * This table stores uploaded documents for workers (ID copies, contracts, certificates, etc.)
 */
export class CreateWorkerDocumentsTable1737036000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // Create document type enum
        await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE worker_documents_type_enum AS ENUM (
          'ID_COPY',
          'CONTRACT',
          'CERTIFICATE',
          'TAX_DOCUMENT',
          'OTHER'
        );
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

        // Create worker_documents table
        await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS worker_documents (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        "workerId" UUID NOT NULL,
        type worker_documents_type_enum NOT NULL DEFAULT 'OTHER',
        name VARCHAR NOT NULL,
        url VARCHAR NOT NULL,
        "fileSize" INTEGER,
        "mimeType" VARCHAR,
        "expiresAt" DATE,
        notes TEXT,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "FK_worker_documents_workerId" FOREIGN KEY ("workerId")
          REFERENCES workers(id) ON DELETE CASCADE
      )
    `);

        // Create index for performance
        await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_worker_documents_workerId_createdAt"
        ON worker_documents ("workerId", "createdAt")
    `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_worker_documents_workerId_createdAt"`);
        await queryRunner.query(`DROP TABLE IF EXISTS worker_documents CASCADE`);
        await queryRunner.query(`DROP TYPE IF EXISTS worker_documents_type_enum`);
    }
}
