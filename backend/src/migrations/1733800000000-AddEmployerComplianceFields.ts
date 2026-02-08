import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddEmployerComplianceFields1733800000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Rename nhifNumber to shifNumber in users table (if nhifNumber exists)
    const hasNhifColumn = await queryRunner.query(`
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'nhifNumber'
    `);
    if (hasNhifColumn.length > 0) {
      await queryRunner.renameColumn('users', 'nhifNumber', 'shifNumber');
    }

    // 2. Add Compliance & Payment Fields (only if they don't exist)
    const columnsToAdd = [
      { name: 'businessName', type: 'varchar', isNullable: true },
      { name: 'bankName', type: 'varchar', isNullable: true },
      { name: 'bankAccount', type: 'varchar', isNullable: true },
      { name: 'mpesaPaybill', type: 'varchar', isNullable: true },
      { name: 'mpesaTill', type: 'varchar', isNullable: true },
    ];

    for (const col of columnsToAdd) {
      const exists = await queryRunner.query(`
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = '${col.name}'
      `);
      if (exists.length === 0) {
        await queryRunner.addColumn('users', new TableColumn(col));
      }
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumns('users', [
      'businessName',
      'bankName',
      'bankAccount',
      'mpesaPaybill',
      'mpesaTill',
    ]);
    await queryRunner.renameColumn('users', 'shifNumber', 'nhifNumber');
  }
}
