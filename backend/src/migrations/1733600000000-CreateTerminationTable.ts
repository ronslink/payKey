import {
  MigrationInterface,
  QueryRunner,
  Table,
  TableForeignKey,
  TableColumn,
} from 'typeorm';

export class CreateTerminationTable1733600000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create terminations table
    await queryRunner.createTable(
      new Table({
        name: 'terminations',
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
            name: 'userId',
            type: 'uuid',
          },
          {
            name: 'reason',
            type: 'enum',
            enum: [
              'RESIGNATION',
              'DISMISSAL',
              'CONTRACT_END',
              'ILLNESS',
              'DEATH',
              'RETIREMENT',
              'REDUNDANCY',
              'OTHER',
            ],
          },
          {
            name: 'terminationDate',
            type: 'date',
          },
          {
            name: 'lastWorkingDate',
            type: 'date',
            isNullable: true,
          },
          {
            name: 'noticePeriodDays',
            type: 'int',
            default: 0,
          },
          {
            name: 'notes',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'proratedSalary',
            type: 'decimal',
            precision: 10,
            scale: 2,
          },
          {
            name: 'unusedLeavePayout',
            type: 'decimal',
            precision: 10,
            scale: 2,
          },
          {
            name: 'severancePay',
            type: 'decimal',
            precision: 10,
            scale: 2,
            default: 0,
          },
          {
            name: 'totalFinalPayment',
            type: 'decimal',
            precision: 10,
            scale: 2,
          },
          {
            name: 'paymentBreakdown',
            type: 'jsonb',
            isNullable: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true,
    );

    // Add Foreign Keys (idempotent - check if they exist first using pg_constraint)
    const workerFkExists = await queryRunner.query(`
      SELECT 1 FROM pg_constraint c
      JOIN pg_class t ON t.oid = c.conrelid
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(c.conkey)
      WHERE c.contype = 'f' 
      AND t.relname = 'terminations' 
      AND a.attname = 'workerId'
    `);
    if (workerFkExists.length === 0) {
      await queryRunner.createForeignKey(
        'terminations',
        new TableForeignKey({
          columnNames: ['workerId'],
          referencedColumnNames: ['id'],
          referencedTableName: 'workers',
          onDelete: 'CASCADE',
        }),
      );
    }

    const userFkExists = await queryRunner.query(`
      SELECT 1 FROM pg_constraint c
      JOIN pg_class t ON t.oid = c.conrelid
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(c.conkey)
      WHERE c.contype = 'f' 
      AND t.relname = 'terminations' 
      AND a.attname = 'userId'
    `);
    if (userFkExists.length === 0) {
      await queryRunner.createForeignKey(
        'terminations',
        new TableForeignKey({
          columnNames: ['userId'],
          referencedColumnNames: ['id'],
          referencedTableName: 'users',
          onDelete: 'CASCADE',
        }),
      );
    }

    // Add columns to workers table if they don't exist
    const table = await queryRunner.getTable('workers');
    if (table) {
      if (!table.findColumnByName('terminationId')) {
        await queryRunner.addColumn(
          'workers',
          new TableColumn({
            name: 'terminationId',
            type: 'uuid',
            isNullable: true,
          }),
        );
      }
      if (!table.findColumnByName('terminatedAt')) {
        await queryRunner.addColumn(
          'workers',
          new TableColumn({
            name: 'terminatedAt',
            type: 'timestamp',
            isNullable: true,
          }),
        );
      }
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('terminations');
    await queryRunner.dropColumn('workers', 'terminationId');
    await queryRunner.dropColumn('workers', 'terminatedAt');
  }
}
