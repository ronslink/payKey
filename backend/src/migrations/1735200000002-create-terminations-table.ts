import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateTerminationsTable1735200000002
  implements MigrationInterface
{
  name = 'CreateTerminationsTable1735200000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create termination_type enum
    await queryRunner.query(
      `CREATE TYPE "public"."terminations_termination_type_enum" AS ENUM('VOLUNTARY', 'INVOLUNTARY', 'RESIGNATION', 'TERMINATION', 'RETIREMENT', 'END_OF_CONTRACT', 'DEATH', 'DISMISSAL')`,
    );

    // Create status enum
    await queryRunner.query(
      `CREATE TYPE "public"."terminations_status_enum" AS ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')`,
    );

    // Create terminations table
    await queryRunner.query(
      `CREATE TABLE "terminations" (
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
      )`,
    );

    // Create indexes
    await queryRunner.query(
      `CREATE INDEX "idx_terminations_workerId" ON "terminations" ("workerId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_terminations_userId" ON "terminations" ("userId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_terminations_status" ON "terminations" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_terminations_date" ON "terminations" ("terminationDate")`,
    );

    // Add foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "terminations" ADD CONSTRAINT "FK_terminations_workerId" FOREIGN KEY ("workerId") REFERENCES "workers"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "terminations" ADD CONSTRAINT "FK_terminations_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "terminations" ADD CONSTRAINT "FK_terminations_completedBy" FOREIGN KEY ("completedBy") REFERENCES "users"("id") ON DELETE SET NULL`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "terminations" DROP CONSTRAINT "FK_terminations_completedBy"`,
    );
    await queryRunner.query(
      `ALTER TABLE "terminations" DROP CONSTRAINT "FK_terminations_userId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "terminations" DROP CONSTRAINT "FK_terminations_workerId"`,
    );

    // Drop indexes
    await queryRunner.query(`DROP INDEX "idx_terminations_date"`);
    await queryRunner.query(`DROP INDEX "idx_terminations_status"`);
    await queryRunner.query(`DROP INDEX "idx_terminations_userId"`);
    await queryRunner.query(`DROP INDEX "idx_terminations_workerId"`);

    // Drop table
    await queryRunner.query(`DROP TABLE "terminations"`);

    // Drop enums
    await queryRunner.query(`DROP TYPE "public"."terminations_status_enum"`);
    await queryRunner.query(
      `DROP TYPE "public"."terminations_termination_type_enum"`,
    );
  }
}
