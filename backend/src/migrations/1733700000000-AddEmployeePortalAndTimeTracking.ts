import { MigrationInterface, QueryRunner, Table, TableColumn } from 'typeorm';

export class AddEmployeePortalAndTimeTracking1733700000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // ========================================
    // Create time_entries table
    // ========================================
    await queryRunner.createTable(
      new Table({
        name: 'time_entries',
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
            name: 'recordedById',
            type: 'uuid',
            isNullable: true,
          },
          {
            name: 'clockIn',
            type: 'timestamp',
          },
          {
            name: 'clockOut',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'totalHours',
            type: 'decimal',
            precision: 5,
            scale: 2,
            isNullable: true,
          },
          {
            name: 'breakMinutes',
            type: 'int',
            default: 0,
          },
          {
            name: 'clockInLat',
            type: 'decimal',
            precision: 10,
            scale: 8,
            isNullable: true,
          },
          {
            name: 'clockInLng',
            type: 'decimal',
            precision: 11,
            scale: 8,
            isNullable: true,
          },
          {
            name: 'clockOutLat',
            type: 'decimal',
            precision: 10,
            scale: 8,
            isNullable: true,
          },
          {
            name: 'clockOutLng',
            type: 'decimal',
            precision: 11,
            scale: 8,
            isNullable: true,
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['ACTIVE', 'COMPLETED', 'ADJUSTED', 'CANCELLED'],
            default: "'ACTIVE'",
          },
          {
            name: 'notes',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'adjustmentReason',
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

    // Create indexes for time_entries
    await queryRunner.query(
      `CREATE INDEX "IDX_time_entries_worker_clockin" ON "time_entries" ("workerId", "clockIn")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_time_entries_user_clockin" ON "time_entries" ("userId", "clockIn")`,
    );

    // ========================================
    // Add Employee Portal fields to users table
    // ========================================
    const usersTable = await queryRunner.getTable('users');

    if (usersTable) {
      if (!usersTable.findColumnByName('employerId')) {
        await queryRunner.addColumn(
          'users',
          new TableColumn({
            name: 'employerId',
            type: 'uuid',
            isNullable: true,
          }),
        );
      }

      if (!usersTable.findColumnByName('linkedWorkerId')) {
        await queryRunner.addColumn(
          'users',
          new TableColumn({
            name: 'linkedWorkerId',
            type: 'uuid',
            isNullable: true,
          }),
        );
      }

      if (!usersTable.findColumnByName('phoneNumber')) {
        await queryRunner.addColumn(
          'users',
          new TableColumn({
            name: 'phoneNumber',
            type: 'varchar',
            isNullable: true,
          }),
        );
      }

      if (!usersTable.findColumnByName('pin')) {
        await queryRunner.addColumn(
          'users',
          new TableColumn({
            name: 'pin',
            type: 'varchar',
            isNullable: true,
          }),
        );
      }
    }

    // ========================================
    // Add Employee Portal fields to workers table
    // ========================================
    const workersTable = await queryRunner.getTable('workers');

    if (workersTable) {
      if (!workersTable.findColumnByName('linkedUserId')) {
        await queryRunner.addColumn(
          'workers',
          new TableColumn({
            name: 'linkedUserId',
            type: 'uuid',
            isNullable: true,
          }),
        );
      }

      if (!workersTable.findColumnByName('inviteCode')) {
        await queryRunner.addColumn(
          'workers',
          new TableColumn({
            name: 'inviteCode',
            type: 'varchar',
            length: '10',
            isNullable: true,
          }),
        );
      }

      if (!workersTable.findColumnByName('inviteCodeExpiry')) {
        await queryRunner.addColumn(
          'workers',
          new TableColumn({
            name: 'inviteCodeExpiry',
            type: 'timestamp',
            isNullable: true,
          }),
        );
      }
    }

    // Note: UserRole enum values (EMPLOYER, WORKER) are stored as varchar
    // No need to modify PostgreSQL enum type
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop time_entries table
    await queryRunner.dropTable('time_entries', true);

    // Remove columns from users table
    const usersTable = await queryRunner.getTable('users');
    if (usersTable) {
      if (usersTable.findColumnByName('employerId')) {
        await queryRunner.dropColumn('users', 'employerId');
      }
      if (usersTable.findColumnByName('linkedWorkerId')) {
        await queryRunner.dropColumn('users', 'linkedWorkerId');
      }
      if (usersTable.findColumnByName('phoneNumber')) {
        await queryRunner.dropColumn('users', 'phoneNumber');
      }
      if (usersTable.findColumnByName('pin')) {
        await queryRunner.dropColumn('users', 'pin');
      }
    }

    // Remove columns from workers table
    const workersTable = await queryRunner.getTable('workers');
    if (workersTable) {
      if (workersTable.findColumnByName('linkedUserId')) {
        await queryRunner.dropColumn('workers', 'linkedUserId');
      }
      if (workersTable.findColumnByName('inviteCode')) {
        await queryRunner.dropColumn('workers', 'inviteCode');
      }
      if (workersTable.findColumnByName('inviteCodeExpiry')) {
        await queryRunner.dropColumn('workers', 'inviteCodeExpiry');
      }
    }
  }
}
