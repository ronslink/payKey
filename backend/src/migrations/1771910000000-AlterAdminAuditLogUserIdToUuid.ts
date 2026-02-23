import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlterAdminAuditLogUserIdToUuid1771910000000 implements MigrationInterface {
  name = 'AlterAdminAuditLogUserIdToUuid1771910000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Drop the index on adminUserId before altering the column type
    await queryRunner.query(`
      DROP INDEX IF EXISTS "IDX_admin_audit_logs_adminUserId"
    `);

    // Cast existing varchar values to uuid (safe since all stored values are
    // valid uuid strings from logAction calls, or NULL)
    await queryRunner.query(`
      ALTER TABLE "admin_audit_logs"
        ALTER COLUMN "adminUserId" TYPE uuid USING "adminUserId"::uuid
    `);

    // Re-create the index with the correct type
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_admin_audit_logs_adminUserId"
        ON "admin_audit_logs" ("adminUserId")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS "IDX_admin_audit_logs_adminUserId"
    `);

    await queryRunner.query(`
      ALTER TABLE "admin_audit_logs"
        ALTER COLUMN "adminUserId" TYPE character varying USING "adminUserId"::text
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_admin_audit_logs_adminUserId"
        ON "admin_audit_logs" ("adminUserId")
    `);
  }
}
