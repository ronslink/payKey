import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPostRetirementMedicalContribution1784592000000 implements MigrationInterface {
  name = 'AddPostRetirementMedicalContribution1784592000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "workers"
      ADD COLUMN IF NOT EXISTS "postRetirementMedicalContribution" decimal(12,2) NOT NULL DEFAULT 0
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "workers"
      DROP COLUMN IF EXISTS "postRetirementMedicalContribution"
    `);
  }
}
