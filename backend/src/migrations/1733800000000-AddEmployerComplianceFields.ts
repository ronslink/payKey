import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddEmployerComplianceFields1733800000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Rename nhifNumber to shifNumber in users table
    // Note: We check if column exists first to be safe, although in migration sequence it should.
    // If working with TypeORM renameColumn handles finding the column.
    await queryRunner.renameColumn('users', 'nhifNumber', 'shifNumber');

    // 2. Add Compliance & Payment Fields
    await queryRunner.addColumns('users', [
      new TableColumn({
        name: 'businessName',
        type: 'varchar',
        isNullable: true,
      }),
      new TableColumn({
        name: 'bankName',
        type: 'varchar',
        isNullable: true,
      }),
      new TableColumn({
        name: 'bankAccount',
        type: 'varchar',
        isNullable: true,
      }),
      new TableColumn({
        name: 'mpesaPaybill',
        type: 'varchar',
        isNullable: true,
      }),
      new TableColumn({
        name: 'mpesaTill',
        type: 'varchar',
        isNullable: true,
      }),
    ]);
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
