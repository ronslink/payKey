import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds where a time entry came from and whether payroll may count it.
 *
 * Existing rows are classified from the recorder: a clock-in records the
 * employee's user id, while an employer-entered entry records the employer's id
 * (the same value as the entry's `userId`). Clocked rows are included as they
 * always were; anything the employer typed in starts PENDING so payroll cannot
 * pay it without a decision.
 */
export class AddTimeEntryPayrollDecision1784700000000 implements MigrationInterface {
  name = 'AddTimeEntryPayrollDecision1784700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."time_entries_source_enum" AS ENUM('CLOCK', 'ENTERED')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."time_entries_payrolldecision_enum" AS ENUM('PENDING', 'INCLUDED', 'EXCLUDED')`,
    );

    await queryRunner.query(`
      ALTER TABLE "time_entries"
        ADD COLUMN "source" "public"."time_entries_source_enum" NOT NULL DEFAULT 'CLOCK',
        ADD COLUMN "payrollDecision" "public"."time_entries_payrolldecision_enum" NOT NULL DEFAULT 'PENDING',
        ADD COLUMN "payrollDecidedAt" TIMESTAMP,
        ADD COLUMN "payrollDecidedBy" uuid
    `);

    await queryRunner.query(`
      UPDATE "time_entries"
      SET "source" = CASE
        WHEN "recordedById" IS NOT NULL AND "recordedById" = "userId" THEN 'ENTERED'::"public"."time_entries_source_enum"
        ELSE 'CLOCK'::"public"."time_entries_source_enum"
      END
    `);

    await queryRunner.query(`
      UPDATE "time_entries"
      SET "payrollDecision" = CASE
            WHEN "source" = 'ENTERED' THEN 'PENDING'::"public"."time_entries_payrolldecision_enum"
            ELSE 'INCLUDED'::"public"."time_entries_payrolldecision_enum"
          END,
          "payrollDecidedAt" = CASE
            WHEN "source" = 'ENTERED' THEN NULL
            ELSE COALESCE("updatedAt", "createdAt", now())
          END,
          "payrollDecidedBy" = CASE
            WHEN "source" = 'ENTERED' THEN NULL
            ELSE "recordedById"
          END
    `);

    await queryRunner.query(
      `CREATE INDEX "IDX_time_entries_user_payroll" ON "time_entries" ("userId", "payrollDecision")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_time_entries_user_payroll"`,
    );
    await queryRunner.query(`
      ALTER TABLE "time_entries"
        DROP COLUMN "payrollDecidedBy",
        DROP COLUMN "payrollDecidedAt",
        DROP COLUMN "payrollDecision",
        DROP COLUMN "source"
    `);
    await queryRunner.query(
      `DROP TYPE "public"."time_entries_payrolldecision_enum"`,
    );
    await queryRunner.query(`DROP TYPE "public"."time_entries_source_enum"`);
  }
}
