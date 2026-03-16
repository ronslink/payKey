import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlterSubscriptionPaymentsUserIdToUuid1700000000000 implements MigrationInterface {
  name = 'AlterSubscriptionPaymentsUserIdToUuid1700000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Change userId from varchar to uuid
    await queryRunner.query(`
            ALTER TABLE "subscription_payments" 
            ALTER COLUMN "userId" TYPE uuid USING "userId"::uuid
        `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
            ALTER TABLE "subscription_payments" 
            ALTER COLUMN "userId" TYPE varchar USING "userId"::varchar
        `);
  }
}
