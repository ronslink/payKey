import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSubscriptionsTables1735200000002 implements MigrationInterface {
  name = 'CreateSubscriptionsTables1735200000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create subscription_status enum
    await queryRunner.query(
      `CREATE TYPE "public"."subscriptions_status_enum" AS ENUM('ACTIVE', 'CANCELLED', 'EXPIRED', 'PAST_DUE', 'TRIAL')`,
    );

    // Create subscription_tier enum  
    await queryRunner.query(
      `CREATE TYPE "public"."subscriptions_tier_enum" AS ENUM('FREE', 'BASIC', 'GOLD', 'PLATINUM')`,
    );

    // Create payment_status enum
    await queryRunner.query(
      `CREATE TYPE "public"."subscription_payments_status_enum" AS ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')`,
    );

    // Create payment_method enum
    await queryRunner.query(
      `CREATE TYPE "public"."subscription_payments_payment_method_enum" AS ENUM('Credit Card', 'Bank Transfer', 'PayPal', 'stripe')`,
    );

    // Create subscriptions table
    await queryRunner.query(
      `CREATE TABLE "subscriptions" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "userId" uuid NOT NULL,
        "tier" "public"."subscriptions_tier_enum" NOT NULL DEFAULT 'FREE',
        "status" "public"."subscriptions_status_enum" NOT NULL DEFAULT 'ACTIVE',
        "amount" decimal(10,2),
        "currency" varchar NOT NULL DEFAULT 'USD',
        "startDate" TIMESTAMP WITH TIME ZONE,
        "endDate" TIMESTAMP WITH TIME ZONE,
        "nextBillingDate" TIMESTAMP WITH TIME ZONE,
        "stripeSubscriptionId" varchar,
        "stripePriceId" varchar,
        "notes" text,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_subscriptions_id" PRIMARY KEY ("id")
      )`,
    );

    // Create subscription_payments table
    await queryRunner.query(
      `CREATE TABLE "subscription_payments" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "subscriptionId" uuid NOT NULL,
        "userId" uuid NOT NULL,
        "amount" decimal(10,2) NOT NULL,
        "currency" varchar NOT NULL DEFAULT 'USD',
        "status" "public"."subscription_payments_status_enum" NOT NULL DEFAULT 'COMPLETED',
        "paymentMethod" "public"."subscription_payments_payment_method_enum" NOT NULL,
        "billingPeriod" varchar NOT NULL,
        "periodStart" TIMESTAMP WITH TIME ZONE NOT NULL,
        "periodEnd" TIMESTAMP WITH TIME ZONE NOT NULL,
        "dueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
        "paidDate" TIMESTAMP WITH TIME ZONE,
        "invoiceNumber" varchar,
        "paymentProvider" varchar,
        "transactionId" varchar,
        "metadata" jsonb,
        "notes" text,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_subscription_payments_id" PRIMARY KEY ("id")
      )`,
    );

    // Create indexes
    await queryRunner.query(
      `CREATE INDEX "idx_subscriptions_userId" ON "subscriptions" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_subscriptions_status" ON "subscriptions" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_subscriptions_tier" ON "subscriptions" ("tier")`,
    );
    
    await queryRunner.query(
      `CREATE INDEX "idx_subscription_payments_subscriptionId" ON "subscription_payments" ("subscriptionId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_subscription_payments_userId" ON "subscription_payments" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_subscription_payments_status" ON "subscription_payments" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_subscription_payments_createdAt" ON "subscription_payments" ("createdAt")`,
    );

    // Add foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "subscriptions" ADD CONSTRAINT "FK_subscriptions_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    
    await queryRunner.query(
      `ALTER TABLE "subscription_payments" ADD CONSTRAINT "FK_subscription_payments_subscriptionId" FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "subscription_payments" ADD CONSTRAINT "FK_subscription_payments_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "subscription_payments" DROP CONSTRAINT "FK_subscription_payments_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "subscription_payments" DROP CONSTRAINT "FK_subscription_payments_subscriptionId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "subscriptions" DROP CONSTRAINT "FK_subscriptions_userId"`,
    );

    // Drop indexes
    await queryRunner.query(`DROP INDEX "idx_subscription_payments_createdAt"`);
    await queryRunner.query(`DROP INDEX "idx_subscription_payments_status"`);
    await queryRunner.query(`DROP INDEX "idx_subscription_payments_userId"`);
    await queryRunner.query(`DROP INDEX "idx_subscription_payments_subscriptionId"`);
    await queryRunner.query(`DROP INDEX "idx_subscriptions_tier"`);
    await queryRunner.query(`DROP INDEX "idx_subscriptions_status"`);
    await queryRunner.query(`DROP INDEX "idx_subscriptions_userId"`);

    // Drop tables
    await queryRunner.query(`DROP TABLE "subscription_payments"`);
    await queryRunner.query(`DROP TABLE "subscriptions"`);

    // Drop enums
    await queryRunner.query(`DROP TYPE "public"."subscription_payments_payment_method_enum"`);
    await queryRunner.query(`DROP TYPE "public"."subscription_payments_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."subscriptions_tier_enum"`);
    await queryRunner.query(`DROP TYPE "public"."subscriptions_status_enum"`);
  }
}