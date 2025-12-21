
import { MigrationInterface, QueryRunner, Table, TableForeignKey } from 'typeorm';

export class CreateLeaveRequestsTable1734000000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // Check if table already exists (for idempotency)
        const tableExists = await queryRunner.hasTable('leave_requests');

        if (!tableExists) {
            await queryRunner.createTable(
                new Table({
                    name: 'leave_requests',
                    columns: [
                        {
                            name: 'id',
                            type: 'uuid',
                            isPrimary: true,
                            generationStrategy: 'uuid',
                            default: 'uuid_generate_v4()',
                        },
                        {
                            name: 'workerId',
                            type: 'uuid',
                        },
                        {
                            name: 'requestedById',
                            type: 'uuid',
                        },
                        {
                            name: 'leaveType',
                            type: 'varchar',
                        },
                        {
                            name: 'startDate',
                            type: 'date',
                        },
                        {
                            name: 'endDate',
                            type: 'date',
                        },
                        {
                            name: 'totalDays',
                            type: 'int',
                        },
                        {
                            name: 'reason',
                            type: 'text',
                            isNullable: true,
                        },
                        {
                            name: 'status',
                            type: 'varchar',
                            default: "'PENDING'",
                        },
                        {
                            name: 'approvedById',
                            type: 'uuid',
                            isNullable: true,
                        },
                        {
                            name: 'approvedAt',
                            type: 'timestamp',
                            isNullable: true,
                        },
                        {
                            name: 'rejectionReason',
                            type: 'text',
                            isNullable: true,
                        },
                        {
                            name: 'dailyPayRate',
                            type: 'decimal',
                            precision: 10,
                            scale: 2,
                            isNullable: true,
                        },
                        {
                            name: 'paidLeave',
                            type: 'boolean',
                            default: false,
                        },
                        {
                            name: 'emergencyContact',
                            type: 'text',
                            isNullable: true,
                        },
                        {
                            name: 'emergencyPhone',
                            type: 'text',
                            isNullable: true,
                        },
                        {
                            name: 'createdAt',
                            type: 'timestamp',
                            default: 'CURRENT_TIMESTAMP',
                        },
                        {
                            name: 'updatedAt',
                            type: 'timestamp',
                            default: 'CURRENT_TIMESTAMP',
                        },
                    ],
                }),
                true,
            );

            await queryRunner.createForeignKey(
                'leave_requests',
                new TableForeignKey({
                    columnNames: ['workerId'],
                    referencedColumnNames: ['id'],
                    referencedTableName: 'workers',
                    onDelete: 'CASCADE',
                }),
            );

            await queryRunner.createForeignKey(
                'leave_requests',
                new TableForeignKey({
                    columnNames: ['requestedById'],
                    referencedColumnNames: ['id'],
                    referencedTableName: 'users',
                    onDelete: 'CASCADE',
                }),
            );

            await queryRunner.createForeignKey(
                'leave_requests',
                new TableForeignKey({
                    columnNames: ['approvedById'],
                    referencedColumnNames: ['id'],
                    referencedTableName: 'users',
                    onDelete: 'SET NULL',
                }),
            );
        }
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        const table = await queryRunner.getTable('leave_requests');
        if (table) {
            const foreignKeys = table.foreignKeys;
            for (const foreignKey of foreignKeys) {
                await queryRunner.dropForeignKey('leave_requests', foreignKey);
            }
        }
        await queryRunner.dropTable('leave_requests', true);
    }
}
