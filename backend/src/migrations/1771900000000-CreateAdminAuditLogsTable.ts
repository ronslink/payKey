import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAdminAuditLogsTable1771900000000 implements MigrationInterface {
  name = 'CreateAdminAuditLogsTable1771900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "admin_audit_logs" (
        "id"          uuid                NOT NULL DEFAULT uuid_generate_v4(),
        "adminUserId" character varying,
        "action"      character varying   NOT NULL,
        "entityType"  character varying   NOT NULL,
        "entityId"    character varying,
        "oldValues"   jsonb,
        "newValues"   jsonb,
        "ipAddress"   character varying,
        "userAgent"   character varying,
        "createdAt"   TIMESTAMP           NOT NULL DEFAULT now(),
        CONSTRAINT "PK_admin_audit_logs" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_admin_audit_logs_adminUserId"
        ON "admin_audit_logs" ("adminUserId")
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_admin_audit_logs_entityType"
        ON "admin_audit_logs" ("entityType")
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_admin_audit_logs_action"
        ON "admin_audit_logs" ("action")
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_admin_audit_logs_createdAt"
        ON "admin_audit_logs" ("createdAt" DESC)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "admin_audit_logs"`);
  }
}
