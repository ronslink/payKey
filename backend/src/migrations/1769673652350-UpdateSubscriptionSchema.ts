import { MigrationInterface, QueryRunner } from 'typeorm';

export class UpdateSubscriptionSchema1769673652350 implements MigrationInterface {
  name = 'UpdateSubscriptionSchema1769673652350';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create tables if not exist
    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "exchange_rates" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "sourceCurrency" character varying NOT NULL, "targetCurrency" character varying NOT NULL, "rate" numeric(10,4) NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_33a614bad9e61956079d817ebe2" PRIMARY KEY ("id"))`,
    );

    // Check and Create Enums
    const hasNotifType = await queryRunner.query(
      `SELECT 1 FROM pg_type WHERE typname = 'notifications_type_enum'`,
    );
    if (hasNotifType.length === 0) {
      await queryRunner.query(
        `CREATE TYPE "public"."notifications_type_enum" AS ENUM('SMS', 'EMAIL', 'PUSH')`,
      );
    }

    const hasNotifStatus = await queryRunner.query(
      `SELECT 1 FROM pg_type WHERE typname = 'notifications_status_enum'`,
    );
    if (hasNotifStatus.length === 0) {
      await queryRunner.query(
        `CREATE TYPE "public"."notifications_status_enum" AS ENUM('PENDING', 'SENT', 'DELIVERED', 'FAILED')`,
      );
    }

    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "notifications" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "type" "public"."notifications_type_enum" NOT NULL, "status" "public"."notifications_status_enum" NOT NULL DEFAULT 'PENDING', "recipient" character varying, "subject" character varying, "message" text NOT NULL, "messageId" character varying, "errorMessage" character varying, "metadata" jsonb, "sentAt" TIMESTAMP, "deliveredAt" TIMESTAMP, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_6a72c3c0f683f6462415e653c3a" PRIMARY KEY ("id"))`,
    );

    // Indices (IF NOT EXISTS not standard in all Postgres versions for CREATE INDEX, but we can wrap or ignore)
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_692a909ee0fa9383e7859f9b40" ON "notifications" ("userId") `,
    );

    const hasDevicePlatform = await queryRunner.query(
      `SELECT 1 FROM pg_type WHERE typname = 'device_tokens_platform_enum'`,
    );
    if (hasDevicePlatform.length === 0) {
      await queryRunner.query(
        `CREATE TYPE "public"."device_tokens_platform_enum" AS ENUM('ANDROID', 'IOS', 'WEB')`,
      );
    }

    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "device_tokens" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "token" character varying NOT NULL, "platform" "public"."device_tokens_platform_enum" NOT NULL, "deviceId" character varying, "isActive" boolean NOT NULL DEFAULT true, "lastUsedAt" TIMESTAMP, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_84700be257607cfb1f9dc2e52c3" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_511957e3e8443429dc3fb00120" ON "device_tokens" ("userId") `,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_977e24c520c49436d08e5eeea8" ON "device_tokens" ("token") `,
    );

    // Foreign Keys - checking existence is harder in raw SQL one-liner, but TypeORM might handle duplicate constraint error or we can wrap in DO block.
    // Simple hack: Try/Catch via suppression or check constraint existence.
    // For now, let's assume if table existed, FK might exist.
    // Better: use explicit checks if table was created.
    // Actually, if table exists, we shouldn't add constraint again if it exists.
    // Let's use DO block for constraints or simple ignore if fails?
    // Safest: Check constraint existence.

    const hasFKNotif = await queryRunner.query(
      `SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'FK_692a909ee0fa9383e7859f9b406'`,
    );
    if (hasFKNotif.length === 0) {
      await queryRunner.query(
        `ALTER TABLE "notifications" ADD CONSTRAINT "FK_692a909ee0fa9383e7859f9b406" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
      );
    }

    const hasFKDevice = await queryRunner.query(
      `SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'FK_511957e3e8443429dc3fb00120c'`,
    );
    if (hasFKDevice.length === 0) {
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
    await queryRunner.query(`DROP TABLE "exchange_rates"`);
  }
}
