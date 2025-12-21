import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';

async function createMissingTables() {
  const configService = new ConfigService();

  const dataSource = new DataSource({
    type: 'postgres',
    host: configService.get('DB_HOST', 'localhost'),
    port: configService.get('DB_PORT', 5432),
    username: configService.get('DB_USERNAME', 'postgres'),
    password: configService.get('DB_PASSWORD', 'admin'),
    database: configService.get('DB_NAME', 'paykey'),
    synchronize: false,
    logging: true,
  });

  try {
    await dataSource.initialize();
    console.log('Connected to database successfully');

    // Create ENUM types first
    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."tax_configs_taxtype_enum" AS ENUM('PAYE', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY');
    `);

    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."tax_configs_ratetype_enum" AS ENUM('PERCENTAGE', 'GRADUATED', 'TIERED');
    `);

    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."tax_payments_taxtype_enum" AS ENUM('PAYE', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY');
    `);

    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."tax_payments_paymentmethod_enum" AS ENUM('MPESA', 'BANK');
    `);

    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."tax_payments_status_enum" AS ENUM('PENDING', 'PAID', 'OVERDUE');
    `);

    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."subscriptions_tier_enum" AS ENUM('FREE', 'BASIC', 'GOLD', 'PLATINUM');
    `);

    await dataSource.query(`
      CREATE TYPE IF NOT EXISTS "public"."subscriptions_status_enum" AS ENUM('ACTIVE', 'CANCELLED', 'EXPIRED', 'PAST_DUE', 'TRIAL');
    `);

    // Create tax_configs table
    await dataSource.query(`
      CREATE TABLE IF NOT EXISTS "tax_configs" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "taxType" "public"."tax_configs_taxtype_enum" NOT NULL,
        "rateType" "public"."tax_configs_ratetype_enum" NOT NULL,
        "effectiveFrom" date NOT NULL,
        "effectiveTo" date,
        "configuration" jsonb NOT NULL,
        "paymentDeadline" character varying NOT NULL DEFAULT '9th of following month',
        "isActive" boolean NOT NULL DEFAULT true,
        "notes" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_fefada95a3b9edeac02a5c7b5dd" PRIMARY KEY ("id")
      );
    `);

    // Create tax_payments table
    await dataSource.query(`
      CREATE TABLE IF NOT EXISTS "tax_payments" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" uuid NOT NULL,
        "taxType" "public"."tax_payments_taxtype_enum" NOT NULL,
        "paymentYear" integer NOT NULL,
        "paymentMonth" integer NOT NULL,
        "amount" numeric(12,2) NOT NULL,
        "paymentDate" date,
        "paymentMethod" "public"."tax_payments_paymentmethod_enum",
        "receiptNumber" character varying,
        "status" "public"."tax_payments_status_enum" NOT NULL DEFAULT 'PENDING',
        "notes" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_300678915f007d7c94439ac5dd3" PRIMARY KEY ("id")
      );
    `);

    // Create subscriptions table
    await dataSource.query(`
      CREATE TABLE IF NOT EXISTS "subscriptions" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" uuid NOT NULL,
        "tier" "public"."subscriptions_tier_enum" NOT NULL,
        "status" "public"."subscriptions_status_enum" NOT NULL DEFAULT 'ACTIVE',
        "amount" numeric(10,2),
        "currency" character varying NOT NULL DEFAULT 'USD',
        "startDate" TIMESTAMP WITH TIME ZONE,
        "endDate" TIMESTAMP WITH TIME ZONE,
        "nextBillingDate" TIMESTAMP WITH TIME ZONE,
        "stripeSubscriptionId" character varying,
        "stripePriceId" character varying,
        "notes" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_a87248d73155605cf782be9ee5e" PRIMARY KEY ("id")
      );
    `);

    console.log(
      '\n✅ Successfully created missing tables: tax_configs, tax_payments, subscriptions',
    );
    console.log('🎉 Database schema is now complete!');
  } catch (error) {
    console.error('Error creating tables:', error);
  } finally {
    await dataSource.destroy();
  }
}

createMissingTables();
