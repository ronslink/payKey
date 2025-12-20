import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddPayrollImprovements1734200000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // 1. Create PayrollFrequency enum type
        await queryRunner.query(`
            DO $$ BEGIN
                CREATE TYPE "payroll_frequency_enum" AS ENUM ('WEEKLY', 'BI_WEEKLY', 'MONTHLY');
            EXCEPTION
                WHEN duplicate_object THEN null;
            END $$;
        `);

        // 2. Add defaultPayrollFrequency to users table
        const usersTable = await queryRunner.getTable('users');
        if (usersTable && !usersTable.findColumnByName('defaultPayrollFrequency')) {
            await queryRunner.addColumn(
                'users',
                new TableColumn({
                    name: 'defaultPayrollFrequency',
                    type: 'payroll_frequency_enum',
                    isNullable: true,
                    default: "'MONTHLY'",
                }),
            );
        }

        // 3. Add isOffCycle to pay_periods table
        const payPeriodsTable = await queryRunner.getTable('pay_periods');
        if (payPeriodsTable && !payPeriodsTable.findColumnByName('isOffCycle')) {
            await queryRunner.addColumn(
                'pay_periods',
                new TableColumn({
                    name: 'isOffCycle',
                    type: 'boolean',
                    isNullable: false,
                    default: false,
                }),
            );
        }
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Remove isOffCycle from pay_periods
        const payPeriodsTable = await queryRunner.getTable('pay_periods');
        if (payPeriodsTable?.findColumnByName('isOffCycle')) {
            await queryRunner.dropColumn('pay_periods', 'isOffCycle');
        }

        // Remove defaultPayrollFrequency from users
        const usersTable = await queryRunner.getTable('users');
        if (usersTable?.findColumnByName('defaultPayrollFrequency')) {
            await queryRunner.dropColumn('users', 'defaultPayrollFrequency');
        }

        // Drop enum type
        await queryRunner.query(`DROP TYPE IF EXISTS "payroll_frequency_enum"`);
    }
}
