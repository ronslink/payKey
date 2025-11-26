import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddResidentStatusAndCountryCode1732468867000
  implements MigrationInterface
{
  name = 'AddResidentStatusAndCountryCode1732468867000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD COLUMN "residentStatus" "public"."users_residentstatus_enum"`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD COLUMN "countryCode" character varying`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "countryCode"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "residentStatus"`);
    // Note: Cannot remove enum values in PostgreSQL once added
  }
}
