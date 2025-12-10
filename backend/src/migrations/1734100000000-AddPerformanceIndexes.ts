import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPerformanceIndexes1734100000000 implements MigrationInterface {
    name = 'AddPerformanceIndexes1734100000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Worker indexes
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_workers_userId_isActive" ON "workers" ("userId", "isActive")`,
        );
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_workers_userId_createdAt" ON "workers" ("userId", "createdAt")`,
        );

        // PayrollRecord indexes
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_payroll_records_payPeriodId" ON "payroll_records" ("payPeriodId")`,
        );
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_payroll_records_userId_periodStart" ON "payroll_records" ("userId", "periodStart")`,
        );
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_payroll_records_workerId" ON "payroll_records" ("workerId")`,
        );

        // LeaveRequest indexes
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_leave_requests_workerId_status" ON "leave_requests" ("workerId", "status")`,
        );
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_leave_requests_requestedById" ON "leave_requests" ("requestedById")`,
        );
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_leave_requests_workerId_startDate" ON "leave_requests" ("workerId", "startDate")`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Remove Worker indexes
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_workers_userId_isActive"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_workers_userId_createdAt"`);

        // Remove PayrollRecord indexes
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payroll_records_payPeriodId"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payroll_records_userId_periodStart"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payroll_records_workerId"`);

        // Remove LeaveRequest indexes
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_leave_requests_workerId_status"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_leave_requests_requestedById"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_leave_requests_workerId_startDate"`);
    }
}
