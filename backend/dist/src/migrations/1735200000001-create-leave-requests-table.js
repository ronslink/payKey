"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateLeaveRequestsTable1735200000001 = void 0;
class CreateLeaveRequestsTable1735200000001 {
    name = 'CreateLeaveRequestsTable1735200000001';
    async up(queryRunner) {
        await queryRunner.query(`CREATE TYPE "public"."leave_requests_leave_type_enum" AS ENUM('ANNUAL', 'SICK', 'MATERNITY', 'PATERNITY', 'COMPASSIONATE', 'UNPAID', 'EMERGENCY')`);
        await queryRunner.query(`CREATE TYPE "public"."leave_requests_status_enum" AS ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'COMPLETED')`);
        await queryRunner.query(`CREATE TABLE "leave_requests" (
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
      )`);
        await queryRunner.query(`CREATE INDEX "idx_leave_requests_workerId" ON "leave_requests" ("workerId")`);
        await queryRunner.query(`CREATE INDEX "idx_leave_requests_userId" ON "leave_requests" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_leave_requests_status" ON "leave_requests" ("status")`);
        await queryRunner.query(`CREATE INDEX "idx_leave_requests_dates" ON "leave_requests" ("startDate", "endDate")`);
        await queryRunner.query(`ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE CASCADE`);
        await queryRunner.query(`ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`);
        await queryRunner.query(`ALTER TABLE "leave_requests" ADD CONSTRAINT "FK_leave_requests_approvedBy" FOREIGN KEY ("approvedBy") REFERENCES "users"("id") ON DELETE SET NULL`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_approvedBy"`);
        await queryRunner.query(`ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_userId"`);
        await queryRunner.query(`ALTER TABLE "leave_requests" DROP CONSTRAINT "FK_leave_requests_workerId"`);
        await queryRunner.query(`DROP INDEX "idx_leave_requests_dates"`);
        await queryRunner.query(`DROP INDEX "idx_leave_requests_status"`);
        await queryRunner.query(`DROP INDEX "idx_leave_requests_userId"`);
        await queryRunner.query(`DROP INDEX "idx_leave_requests_workerId"`);
        await queryRunner.query(`DROP TABLE "leave_requests"`);
        await queryRunner.query(`DROP TYPE "public"."leave_requests_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."leave_requests_leave_type_enum"`);
    }
}
exports.CreateLeaveRequestsTable1735200000001 = CreateLeaveRequestsTable1735200000001;
//# sourceMappingURL=1735200000001-create-leave-requests-table.js.map