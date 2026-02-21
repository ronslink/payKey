import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSupportAndSubscriptionPlans1740055200000 implements MigrationInterface {
  name = 'CreateSupportAndSubscriptionPlans1740055200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // ─── subscription_plans table ─────────────────────────────────────────────
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "subscription_plans" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "tier" character varying NOT NULL UNIQUE,
        "name" character varying NOT NULL,
        "priceUSD" numeric(10,2) NOT NULL DEFAULT 0,
        "priceKES" numeric(10,2) NOT NULL DEFAULT 0,
        "priceUSDYearly" numeric(10,2) NOT NULL DEFAULT 0,
        "priceKESYearly" numeric(10,2) NOT NULL DEFAULT 0,
        "workerLimit" integer NOT NULL DEFAULT 1,
        "features" jsonb NOT NULL DEFAULT '[]',
        "importAccess" boolean NOT NULL DEFAULT false,
        "isPopular" boolean NOT NULL DEFAULT false,
        "isActive" boolean NOT NULL DEFAULT true,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_subscription_plans" PRIMARY KEY ("id")
      )
    `);

    // Seed from current hardcoded values
    await queryRunner.query(`
      INSERT INTO "subscription_plans" ("tier","name","priceUSD","priceKES","priceUSDYearly","priceKESYearly","workerLimit","features","importAccess","isPopular","isActive")
      VALUES
        ('FREE','Free',0,0,0,0,1,'["Up to 1 worker","Basic worker management","Automatic tax calculations"]',false,false,true),
        ('BASIC','Basic',9.99,1300,99.99,13000,5,'["Up to 5 workers","Automatic tax calculations","M-Pesa payments","P9 Tax Cards"]',false,true,true),
        ('GOLD','Gold',29.99,3900,299.99,39000,10,'["Up to 10 workers","Automatic tax calculations","M-Pesa payments","P9 Tax Cards","Advanced reporting","Accounting exports","Priority support","Excel worker import"]',true,false,true),
        ('PLATINUM','Platinum',49.99,6500,499.99,65000,20,'["Up to 20 workers","Automatic tax calculations","M-Pesa payments","Leave tracking","Time tracking (clock in/out)","Geofencing","Advanced reporting","Accounting exports","Priority support","Automatic tax payments to KRA","Multi-property management","Excel worker import"]',true,false,true)
      ON CONFLICT ("tier") DO UPDATE SET
        "name" = EXCLUDED."name",
        "priceUSD" = EXCLUDED."priceUSD",
        "priceKES" = EXCLUDED."priceKES",
        "priceUSDYearly" = EXCLUDED."priceUSDYearly",
        "priceKESYearly" = EXCLUDED."priceKESYearly",
        "workerLimit" = EXCLUDED."workerLimit",
        "features" = EXCLUDED."features",
        "importAccess" = EXCLUDED."importAccess",
        "isPopular" = EXCLUDED."isPopular",
        "isActive" = EXCLUDED."isActive"
    `);

    // ─── support_tickets table ────────────────────────────────────────────────
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "support_tickets_status_enum" AS ENUM ('OPEN','IN_PROGRESS','RESOLVED','CLOSED');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "support_tickets_priority_enum" AS ENUM ('LOW','MEDIUM','HIGH');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "support_tickets_category_enum" AS ENUM ('BILLING','PAYROLL','TECHNICAL','TAX','GENERAL');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "support_tickets" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" uuid NOT NULL,
        "subject" character varying NOT NULL,
        "description" text NOT NULL,
        "status" "support_tickets_status_enum" NOT NULL DEFAULT 'OPEN',
        "priority" "support_tickets_priority_enum" NOT NULL DEFAULT 'MEDIUM',
        "category" "support_tickets_category_enum" NOT NULL DEFAULT 'GENERAL',
        "adminNotes" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_support_tickets" PRIMARY KEY ("id"),
        CONSTRAINT "FK_support_tickets_user" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    // ─── support_messages table ───────────────────────────────────────────────
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "support_messages_senderrole_enum" AS ENUM ('USER','ADMIN');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "support_messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "ticketId" uuid NOT NULL,
        "senderId" uuid NOT NULL,
        "senderRole" "support_messages_senderrole_enum" NOT NULL,
        "message" text NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_support_messages" PRIMARY KEY ("id"),
        CONSTRAINT "FK_support_messages_ticket" FOREIGN KEY ("ticketId") REFERENCES "support_tickets"("id") ON DELETE CASCADE
      )
    `);

    // Indexes for common queries
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_support_tickets_userId" ON "support_tickets" ("userId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_support_tickets_status" ON "support_tickets" ("status")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_support_messages_ticketId" ON "support_messages" ("ticketId")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "support_messages"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "support_tickets"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "support_messages_senderrole_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "support_tickets_category_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "support_tickets_priority_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "support_tickets_status_enum"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "subscription_plans"`);
  }
}
