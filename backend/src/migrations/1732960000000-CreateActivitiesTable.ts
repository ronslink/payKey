import { MigrationInterface, QueryRunner, Table, TableForeignKey } from 'typeorm';

export class CreateActivitiesTable1732960000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // Check if table already exists (for idempotency)
        const tableExists = await queryRunner.hasTable('activities');

        if (!tableExists) {
            await queryRunner.createTable(
                new Table({
                    name: 'activities',
                    columns: [
                        {
                            name: 'id',
                            type: 'uuid',
                            isPrimary: true,
                            generationStrategy: 'uuid',
                            default: 'uuid_generate_v4()',
                        },
                        {
                            name: 'userId',
                            type: 'uuid',
                        },
                        {
                            name: 'type',
                            type: 'enum',
                            enum: ['payroll', 'worker', 'tax', 'leave', 'time_tracking', 'accounting'],
                        },
                        {
                            name: 'title',
                            type: 'varchar',
                        },
                        {
                            name: 'description',
                            type: 'varchar',
                        },
                        {
                            name: 'metadata',
                            type: 'jsonb',
                            isNullable: true,
                        },
                        {
                            name: 'timestamp',
                            type: 'timestamp',
                            default: 'CURRENT_TIMESTAMP',
                        },
                    ],
                }),
                true,
            );

            await queryRunner.createForeignKey(
                'activities',
                new TableForeignKey({
                    columnNames: ['userId'],
                    referencedColumnNames: ['id'],
                    referencedTableName: 'users',
                    onDelete: 'CASCADE',
                }),
            );
        }

        // Create index with IF NOT EXISTS for idempotency
        await queryRunner.query(
            `CREATE INDEX IF NOT EXISTS "IDX_activities_userId_timestamp" ON "activities" ("userId", "timestamp" DESC)`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.dropTable('activities', true);
    }
}
