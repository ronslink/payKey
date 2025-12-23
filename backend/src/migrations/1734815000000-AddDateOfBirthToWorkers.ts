import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDateOfBirthToWorkers1734815000000
  implements MigrationInterface
{
  name = 'AddDateOfBirthToWorkers1734815000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "workers" ADD COLUMN IF NOT EXISTS "dateOfBirth" DATE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "workers" DROP COLUMN IF EXISTS "dateOfBirth"`,
    );
  }
}
