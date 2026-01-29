import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreateTaxSubmissionsTable1733570000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    const tableExists = await queryRunner.hasTable('tax_submissions');
    if (tableExists) {
      return;
    }
    // Create new table matching the TaxSubmission Entity definition
    await queryRunner.createTable(
      new Table({
        name: 'tax_submissions',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          { name: 'userId', type: 'uuid' },
          { name: 'payPeriodId', type: 'uuid' },
          {
            name: 'totalPaye',
            type: 'decimal',
            precision: 12,
            scale: 2,
            default: 0,
          },
          {
            name: 'totalNssf',
            type: 'decimal',
            precision: 12,
            scale: 2,
            default: 0,
          },
          {
            name: 'totalNhif',
            type: 'decimal',
            precision: 12,
            scale: 2,
            default: 0,
          },
          {
            name: 'totalHousingLevy',
            type: 'decimal',
            precision: 12,
            scale: 2,
            default: 0,
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['PENDING', 'FILED'],
            default: "'PENDING'",
          },
          { name: 'filingDate', type: 'timestamp', isNullable: true },
          { name: 'createdAt', type: 'timestamp', default: 'now()' },
          { name: 'updatedAt', type: 'timestamp', default: 'now()' },
        ],
        foreignKeys: [
          {
            columnNames: ['payPeriodId'],
            referencedTableName: 'pay_periods',
            referencedColumnNames: ['id'],
            onDelete: 'CASCADE', // or SET NULL? Entity doesn't specify cascade, but PayPeriod deletion implies payroll cleanup.
          },
        ],
      }),
      true,
    );
    // Note: userId likely refers to Users table but Entity doesn't have FK constraint defined explicitly via @ManyToOne for user.
    // But good practice to add FK if guaranteed.
    // However, Entity only had payPeriod FK. I'll stick to Entity or safe generic column.
    // I won't add userId FK just in case, unless Entity has it.
    // Entity: @Column() userId: string; (no relation). So no FK constraint.
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('tax_submissions');
  }
}
