import { MigrationInterface, QueryRunner } from 'typeorm';

export class PayKeyInitialSchema1732456700000 implements MigrationInterface {
  name = 'PayKeyInitialSchema1732456700000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create users table
    await queryRunner.query(`CREATE TABLE "users" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "email" varchar NOT NULL,
            "passwordHash" varchar NOT NULL,
            "role" varchar NOT NULL DEFAULT 'USER',
            "firstName" varchar,
            "lastName" varchar,
            "tier" varchar NOT NULL DEFAULT 'FREE',
            "stripeCustomerId" varchar,
            "kraPin" varchar,
            "nssfNumber" varchar,
            "nhifNumber" varchar,
            "idNumber" varchar,
            "address" varchar,
            "city" varchar,
            "countryId" uuid,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "UQ_users_email" UNIQUE ("email"),
            CONSTRAINT "PK_users_id" PRIMARY KEY ("id")
        )`);

    // Create countries table
    await queryRunner.query(`CREATE TABLE "countries" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "code" varchar NOT NULL,
            "name" varchar NOT NULL,
            "currency" varchar NOT NULL,
            "isActive" boolean DEFAULT true,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "UQ_countries_code" UNIQUE ("code"),
            CONSTRAINT "PK_countries_id" PRIMARY KEY ("id")
        )`);

    // Create properties table
    await queryRunner.query(`CREATE TABLE "properties" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "userId" uuid NOT NULL,
            "name" varchar NOT NULL,
            "address" varchar NOT NULL,
            "latitude" decimal(10,8),
            "longitude" decimal(11,8),
            "geofenceRadius" integer DEFAULT 100,
            "isActive" boolean DEFAULT true,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_properties_id" PRIMARY KEY ("id")
        )`);

    // Create workers table
    await queryRunner.query(`CREATE TABLE "workers" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "employmentType" varchar DEFAULT 'FIXED',
            "hourlyRate" decimal(10,2),
            "userId" uuid NOT NULL,
            "name" varchar NOT NULL,
            "phoneNumber" varchar NOT NULL,
            "idNumber" varchar,
            "kraPin" varchar,
            "salaryGross" decimal(12,2) NOT NULL,
            "startDate" date NOT NULL,
            "isActive" boolean DEFAULT true,
            "leaveBalance" integer DEFAULT 0,
            "email" varchar,
            "nssfNumber" varchar,
            "nhifNumber" varchar,
            "jobTitle" varchar,
            "housingAllowance" decimal(12,2) DEFAULT 0,
            "transportAllowance" decimal(12,2) DEFAULT 0,
            "paymentFrequency" varchar DEFAULT 'MONTHLY',
            "paymentMethod" varchar DEFAULT 'MPESA',
            "mpesaNumber" varchar,
            "bankName" varchar,
            "bankAccount" varchar,
            "notes" text,
            "terminationId" uuid,
            "terminatedAt" TIMESTAMP WITH TIME ZONE,
            "propertyId" uuid,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_workers_id" PRIMARY KEY ("id")
        )`);

    // Create pay_periods table
    await queryRunner.query(`CREATE TABLE "pay_periods" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "name" varchar NOT NULL,
            "startDate" date NOT NULL,
            "endDate" date NOT NULL,
            "userId" uuid NOT NULL,
            "payDate" date,
            "frequency" varchar DEFAULT 'MONTHLY',
            "status" varchar DEFAULT 'DRAFT',
            "totalGrossAmount" decimal(15,2) DEFAULT 0,
            "totalNetAmount" decimal(15,2) DEFAULT 0,
            "totalTaxAmount" decimal(15,2) DEFAULT 0,
            "totalWorkers" integer DEFAULT 0,
            "processedWorkers" integer DEFAULT 0,
            "notes" jsonb,
            "createdBy" uuid,
            "approvedBy" uuid,
            "approvedAt" TIMESTAMP WITH TIME ZONE,
            "processedAt" TIMESTAMP WITH TIME ZONE,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_pay_periods_id" PRIMARY KEY ("id")
        )`);

    // Create payroll_records table
    await queryRunner.query(`CREATE TABLE "payroll_records" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "userId" uuid NOT NULL,
            "workerId" uuid NOT NULL,
            "periodStart" date NOT NULL,
            "periodEnd" date NOT NULL,
            "grossSalary" decimal(10,2) NOT NULL,
            "netSalary" decimal(10,2) NOT NULL,
            "taxAmount" decimal(10,2) NOT NULL,
            "paymentStatus" varchar DEFAULT 'pending',
            "paymentMethod" varchar DEFAULT 'mpesa',
            "paymentDate" TIMESTAMP WITH TIME ZONE,
            "taxBreakdown" jsonb,
            "deductions" jsonb,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_payroll_records_id" PRIMARY KEY ("id")
        )`);

    // Create tax_submissions table
    await queryRunner.query(`CREATE TABLE "tax_submissions" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "userId" uuid NOT NULL,
            "payPeriodId" uuid NOT NULL,
            "totalPaye" decimal(12,2) DEFAULT 0,
            "totalNssf" decimal(12,2) DEFAULT 0,
            "totalNhif" decimal(12,2) DEFAULT 0,
            "totalHousingLevy" decimal(12,2) DEFAULT 0,
            "status" varchar DEFAULT 'PENDING',
            "filingDate" TIMESTAMP WITH TIME ZONE,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_tax_submissions_id" PRIMARY KEY ("id")
        )`);

    // Create tax_tables table
    await queryRunner.query(`CREATE TABLE "tax_tables" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "year" integer NOT NULL,
            "effectiveDate" date NOT NULL,
            "nssfConfig" jsonb NOT NULL,
            "nhifConfig" jsonb NOT NULL,
            "housingLevyRate" decimal(5,4) NOT NULL,
            "payeBands" jsonb NOT NULL,
            "personalRelief" decimal(12,2) NOT NULL,
            "isActive" boolean DEFAULT true,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_tax_tables_id" PRIMARY KEY ("id")
        )`);

    // Create transactions table
    await queryRunner.query(`CREATE TABLE "transactions" (
            "id" uuid NOT NULL DEFAULT gen_random_uuid(),
            "userId" uuid NOT NULL,
            "workerId" uuid,
            "amount" decimal(12,2) NOT NULL,
            "currency" varchar DEFAULT 'KES',
            "type" varchar NOT NULL,
            "status" varchar DEFAULT 'PENDING',
            "providerRef" varchar,
            "propertyId" uuid,
            "metadata" jsonb,
            "payPeriodId" uuid,
            "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PK_transactions_id" PRIMARY KEY ("id")
        )`);

    // Create foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "properties" ADD CONSTRAINT "FK_properties_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "workers" ADD CONSTRAINT "FK_workers_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "workers" ADD CONSTRAINT "FK_workers_propertyId" FOREIGN KEY ("propertyId") REFERENCES "properties"("id") ON DELETE SET NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "pay_periods" ADD CONSTRAINT "FK_pay_periods_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD CONSTRAINT "FK_payroll_records_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" ADD CONSTRAINT "FK_payroll_records_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "tax_submissions" ADD CONSTRAINT "FK_tax_submissions_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "tax_submissions" ADD CONSTRAINT "FK_tax_submissions_payPeriodId" FOREIGN KEY ("payPeriodId") REFERENCES "pay_periods"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" ADD CONSTRAINT "FK_transactions_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" ADD CONSTRAINT "FK_transactions_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE SET NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" ADD CONSTRAINT "FK_transactions_propertyId" FOREIGN KEY ("propertyId") REFERENCES "properties"("id") ON DELETE SET NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" ADD CONSTRAINT "FK_transactions_payPeriodId" FOREIGN KEY ("payPeriodId") REFERENCES "pay_periods"("id") ON DELETE SET NULL`,
    );

    // Create indexes
    await queryRunner.query(
      `CREATE INDEX "idx_users_email" ON "users" ("email")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_workers_userId" ON "workers" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_workers_propertyId" ON "workers" ("propertyId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_pay_periods_userId" ON "pay_periods" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_payroll_records_userId" ON "payroll_records" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_payroll_records_workerId" ON "payroll_records" ("workerId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_payroll_records_period" ON "payroll_records" ("periodStart", "periodEnd")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_tax_submissions_userId" ON "tax_submissions" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_tax_submissions_payPeriodId" ON "tax_submissions" ("payPeriodId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_transactions_userId" ON "transactions" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_transactions_workerId" ON "transactions" ("workerId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_transactions_payPeriodId" ON "transactions" ("payPeriodId")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop indexes
    await queryRunner.query(`DROP INDEX "idx_transactions_payPeriodId"`);
    await queryRunner.query(`DROP INDEX "idx_transactions_workerId"`);
    await queryRunner.query(`DROP INDEX "idx_transactions_userId"`);
    await queryRunner.query(`DROP INDEX "idx_tax_submissions_payPeriodId"`);
    await queryRunner.query(`DROP INDEX "idx_tax_submissions_userId"`);
    await queryRunner.query(`DROP INDEX "idx_payroll_records_period"`);
    await queryRunner.query(`DROP INDEX "idx_payroll_records_workerId"`);
    await queryRunner.query(`DROP INDEX "idx_payroll_records_userId"`);
    await queryRunner.query(`DROP INDEX "idx_pay_periods_userId"`);
    await queryRunner.query(`DROP INDEX "idx_workers_propertyId"`);
    await queryRunner.query(`DROP INDEX "idx_workers_userId"`);
    await queryRunner.query(`DROP INDEX "idx_users_email"`);

    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "transactions" DROP CONSTRAINT "FK_transactions_payPeriodId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" DROP CONSTRAINT "FK_transactions_propertyId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" DROP CONSTRAINT "FK_transactions_workerId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "transactions" DROP CONSTRAINT "FK_transactions_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tax_submissions" DROP CONSTRAINT "FK_tax_submissions_payPeriodId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tax_submissions" DROP CONSTRAINT "FK_tax_submissions_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP CONSTRAINT "FK_payroll_records_workerId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payroll_records" DROP CONSTRAINT "FK_payroll_records_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "pay_periods" DROP CONSTRAINT "FK_pay_periods_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "workers" DROP CONSTRAINT "FK_workers_propertyId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "workers" DROP CONSTRAINT "FK_workers_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "properties" DROP CONSTRAINT "FK_properties_userId"`,
    );

    // Drop tables
    await queryRunner.query(`DROP TABLE "transactions"`);
    await queryRunner.query(`DROP TABLE "tax_tables"`);
    await queryRunner.query(`DROP TABLE "tax_submissions"`);
    await queryRunner.query(`DROP TABLE "payroll_records"`);
    await queryRunner.query(`DROP TABLE "pay_periods"`);
    await queryRunner.query(`DROP TABLE "workers"`);
    await queryRunner.query(`DROP TABLE "properties"`);
    await queryRunner.query(`DROP TABLE "countries"`);
    await queryRunner.query(`DROP TABLE "users"`);
  }
}
