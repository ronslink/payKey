import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddClearingStatusAndBalance1768834604853 implements MigrationInterface {
  name = 'AddClearingStatusAndBalance1768834604853';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create notifications_type_enum if not exists
    const hasNotifType = await queryRunner.query(
      `SELECT 1 FROM pg_type WHERE typname = 'notifications_type_enum'`,
    );
    if (hasNotifType.length === 0) {
      await queryRunner.query(
        `CREATE TYPE "public"."notifications_type_enum" AS ENUM('SMS', 'EMAIL', 'PUSH')`,
      );
    }

    // Create notifications_status_enum if not exists
    const hasNotifStatus = await queryRunner.query(
      `SELECT 1 FROM pg_type WHERE typname = 'notifications_status_enum'`,
    );
    if (hasNotifStatus.length === 0) {
      await queryRunner.query(
        `CREATE TYPE "public"."notifications_status_enum" AS ENUM('PENDING', 'SENT', 'DELIVERED', 'FAILED')`,
      );
    }

    // Create notifications table if not exists
    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "notifications" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "type" "public"."notifications_type_enum" NOT NULL, "status" "public"."notifications_status_enum" NOT NULL DEFAULT 'PENDING', "recipient" character varying, "subject" character varying, "message" text NOT NULL, "messageId" character varying, "errorMessage" character varying, "metadata" jsonb, "sentAt" TIMESTAMP, "deliveredAt" TIMESTAMP, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_6a72c3c0f683f6462415e653c3a" PRIMARY KEY ("id"))`,
    );

    // Create index on notifications(userId) if not exists
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_692a909ee0fa9383e7859f9b40" ON "notifications" ("userId") `,
    );

    // Create device_tokens_platform_enum if not exists
    const hasDevicePlatform = await queryRunner.query(
      `SELECT 1 FROM pg_type WHERE typname = 'device_tokens_platform_enum'`,
    );
    if (hasDevicePlatform.length === 0) {
      await queryRunner.query(
        `CREATE TYPE "public"."device_tokens_platform_enum" AS ENUM('ANDROID', 'IOS', 'WEB')`,
      );
    }

    // Create device_tokens table if not exists
    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "device_tokens" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "token" character varying NOT NULL, "platform" "public"."device_tokens_platform_enum" NOT NULL, "deviceId" character varying, "isActive" boolean NOT NULL DEFAULT true, "lastUsedAt" TIMESTAMP, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_84700be257607cfb1f9dc2e52c3" PRIMARY KEY ("id"))`,
    );

    // Create indices on device_tokens if not exist
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_511957e3e8443429dc3fb00120" ON "device_tokens" ("userId") `,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_977e24c520c49436d08e5eeea8" ON "device_tokens" ("token") `,
    );

    // Add FK to notifications table (idempotent check)
    const notifFkExists = await queryRunner.query(`
            SELECT 1 FROM pg_constraint c
            JOIN pg_class t ON t.oid = c.conrelid
            WHERE c.contype = 'f' AND t.relname = 'notifications' AND c.conname = 'FK_692a909ee0fa9383e7859f9b406'
        `);
    if (notifFkExists.length === 0) {
      await queryRunner.query(
        `ALTER TABLE "notifications" ADD CONSTRAINT "FK_692a909ee0fa9383e7859f9b406" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
      );
    }

    // Add FK to device_tokens table (idempotent check)
    const deviceFkExists = await queryRunner.query(`
            SELECT 1 FROM pg_constraint c
            JOIN pg_class t ON t.oid = c.conrelid
            WHERE c.contype = 'f' AND t.relname = 'device_tokens' AND c.conname = 'FK_511957e3e8443429dc3fb00120c'
        `);
    if (deviceFkExists.length === 0) {
      await queryRunner.query(
        `ALTER TABLE "device_tokens" ADD CONSTRAINT "FK_511957e3e8443429dc3fb00120c" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "device_tokens" DROP CONSTRAINT "FK_511957e3e8443429dc3fb00120c"`,
    );
    await queryRunner.query(
      `ALTER TABLE "notifications" DROP CONSTRAINT "FK_692a909ee0fa9383e7859f9b406"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_977e24c520c49436d08e5eeea8"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_511957e3e8443429dc3fb00120"`,
    );
    await queryRunner.query(`DROP TABLE "device_tokens"`);
    await queryRunner.query(`DROP TYPE "public"."device_tokens_platform_enum"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_692a909ee0fa9383e7859f9b40"`,
    );
    await queryRunner.query(`DROP TABLE "notifications"`);
    await queryRunner.query(`DROP TYPE "public"."notifications_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."notifications_type_enum"`);
  }
}
