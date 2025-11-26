import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateLeaveRequestsTable1735200000001
  implements MigrationInterface
{
  name = 'CreateLeaveRequestsTable1735200000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create leave_types enum
    await queryRunner.query(
      `CREATE TYPE "public"."leave_requests_leave_type_enum" AS ENUM('ANNUAL', 'SICK', 'MATERNITY', 'PATERNITY', 'COMPASSIONATE', 'UNPAID', 'EMERGENCY')`,
    );

    // Create status enum
    await queryRunner.query(
      `CREATE TYPE "public"."leave_requests_status_enum" AS ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'COMPLETED')`,
    );

    // Create leave_requests table
    await queryRunner.query(
      `CREATE TABLE "leave_requests" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "workerId" uuid NOT NULL,
        "userId" uuid NOT NULL,
        "leaveType" "public"."leave_requests_leave_type_enum" NOT NULL,
        "startDate" date NOT NULL,
        "endDate" date NOT NULL,
        "totalDays" integer NOT NULL,
        "reason" text NOT NULL,
        "status" "public"."leave_requests_status_enum" NOT NULL DEFAULT 'PENDING',
        "requestedDate" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "approvedBy" uuid,
        "approvedAt" TIMESTAMP WITH TIME ZONE,
        "rejectedReason" text,
        "actualStartDate" date,
        "actualEndDate" date,
        "actualDays" integer,
        "notes" text,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_leave_requests_id" PRIMARY KEY ("id")
      )`,
    );

    // Create indexes
    await queryRunner.query(
      `CREATE INDEX "idx_leave_requests_workerId" ON "leave_requests" ("workerId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_leave_requests_userId" ON "leave_requests" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_leave_requests_status" ON "leave_requests" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_leave_requests_dates" ON "leave_requests" ("startDate", "endDate")`,
    );

    // Add foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_approvedBy" FOREIGN KEY ("approvedBy") REFERENCES "users"("id") ON DELETE SET NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_approvedBy"`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_workerId"`,
    );

    // Drop indexes
    await queryRunner.query(`DROP INDEX "idx_leave_requests_dates"`);
    await queryRunner.query(`DROP INDEX "idx_leave_requests_status"`);
    await queryRunner.query(`DROP INDEX "idx_leave_requests_userId"`);
    await queryRunner.query(`DROP INDEX "idx_leave_requests_workerId"`);

    // Drop table
    await queryRunner.query(`DROP TABLE "leave_requests"`);

    // Drop enums
    await queryRunner.query(`DROP TYPE "public"."leave_requests_status_enum"`);
    await queryRunner.query(
      `DROP TYPE "public"."leave_requests_leave_type_enum"`,
    );
  }
}
