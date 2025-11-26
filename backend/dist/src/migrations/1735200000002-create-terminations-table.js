"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateTerminationsTable1735200000002 = void 0;
class CreateTerminationsTable1735200000002 {
    name = 'CreateTerminationsTable1735200000002';
    async up(queryRunner) {
        await queryRunner.query(`CREATE TYPE "public"."terminations_termination_type_enum" AS ENUM('VOLUNTARY', 'INVOLUNTARY', 'RESIGNATION', 'TERMINATION', 'RETIREMENT', 'END_OF_CONTRACT', 'DEATH', 'DISMISSAL')`);
        await queryRunner.query(`CREATE TYPE "public"."terminations_status_enum" AS ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')`);
        await queryRunner.query(`CREATE TABLE "terminations" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "workerId" uuid NOT NULL,
        "userId" uuid NOT NULL,
        "terminationType" "public"."terminations_termination_type_enum" NOT NULL,
        "terminationDate" date NOT NULL,
        "noticeDate" date NOT NULL,
        "status" "public"."terminations_status_enum" NOT NULL DEFAULT 'PENDING',
        "reason" text NOT NULL,
        "noticePeriod" integer DEFAULT 0,
        "lastWorkingDay" date NOT NULL,
        "finalSalary" decimal(12,2),
        "severancePay" decimal(12,2) DEFAULT 0,
        "leavePay" decimal(12,2) DEFAULT 0,
        "otherDeductions" decimal(12,2) DEFAULT 0,
        "netFinalPayment" decimal(12,2),
        "exitInterviewNotes" text,
        "knowledgeTransferNotes" text,
        "assetReturnNotes" text,
        "benefitsTerminationDate" date,
        "certificateIssued" boolean DEFAULT false,
        "referenceLetterIssued" boolean DEFAULT false,
        "completedBy" uuid,
        "completedAt" TIMESTAMP WITH TIME ZONE,
        "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PK_terminations_id" PRIMARY KEY ("id")
      )`);
        await queryRunner.query(`CREATE INDEX "idx_terminations_workerId" ON "terminations" ("workerId")`);
        await queryRunner.query(`CREATE INDEX "idx_terminations_userId" ON "terminations" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_terminations_status" ON "terminations" ("status")`);
        await queryRunner.query(`CREATE INDEX "idx_terminations_date" ON "terminations" ("terminationDate")`);
        await queryRunner.query(`ALTER TABLE "terminations" ADD CONSTRAINT "FK_terminations_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE CASCADE`);
        await queryRunner.query(`ALTER TABLE "terminations" ADD CONSTRAINT "FK_terminations_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`);
        await queryRunner.query(`ALTER TABLE "terminations" ADD CONSTRAINT "FK_terminations_completedBy" FOREIGN KEY ("completedBy") REFERENCES "users"("id") ON DELETE SET NULL`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "terminations" DROP CONSTRAINT "FK_terminations_completedBy"`);
        await queryRunner.query(`ALTER TABLE "terminations" DROP CONSTRAINT "FK_terminations_userId"`);
        await queryRunner.query(`ALTER TABLE "terminations" DROP CONSTRAINT "FK_terminations_workerId"`);
        await queryRunner.query(`DROP INDEX "idx_terminations_date"`);
        await queryRunner.query(`DROP INDEX "idx_terminations_status"`);
        await queryRunner.query(`DROP INDEX "idx_terminations_userId"`);
        await queryRunner.query(`DROP INDEX "idx_terminations_workerId"`);
        await queryRunner.query(`DROP TABLE "terminations"`);
        await queryRunner.query(`DROP TYPE "public"."terminations_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."terminations_termination_type_enum"`);
    }
}
exports.CreateTerminationsTable1735200000002 = CreateTerminationsTable1735200000002;
//# sourceMappingURL=1735200000002-create-terminations-table.js.map