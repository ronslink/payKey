import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class RecreateTaxPaymentsTable1733560000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Check if table exists
    const tableExists = await queryRunner.hasTable('tax_payments');
    if (tableExists) {
      // Check if it's the old version (missing paymentYear)
      const hasPaymentYear = await queryRunner.hasColumn('tax_payments', 'paymentYear');
      if (hasPaymentYear) {
        return; // Already migrated
      }
      // If old version, drop it
      await queryRunner.dropTable('tax_payments');
    }

    // Create new table matching the Entity definition
    await queryRunner.createTable(
      new Table({
        name: 'tax_payments',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          { name: 'userId', type: 'uuid' },
          {
            name: 'taxType',
            type: 'enum',
            enum: ['PAYE', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY'],
          },
          { name: 'paymentYear', type: 'int' },
          { name: 'paymentMonth', type: 'int' },
          { name: 'amount', type: 'decimal', precision: 12, scale: 2 },
          { name: 'paymentDate', type: 'date', isNullable: true },
          {
            name: 'paymentMethod',
            type: 'enum',
            enum: ['MPESA', 'BANK'],
            isNullable: true,
          },
          { name: 'receiptNumber', type: 'varchar', isNullable: true },
          {
            name: 'status',
            type: 'enum',
            enum: ['PENDING', 'PAID', 'OVERDUE'],
            default: "'PENDING'",
          },
          { name: 'notes', type: 'text', isNullable: true },
          { name: 'createdAt', type: 'timestamp', default: 'now()' },
          { name: 'updatedAt', type: 'timestamp', default: 'now()' },
        ],
        foreignKeys: [
          {
            columnNames: ['userId'],
            referencedTableName: 'users',
            referencedColumnNames: ['id'],
            onDelete: 'CASCADE',
          },
        ],
      }),
      true,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('tax_payments');
  }
}
