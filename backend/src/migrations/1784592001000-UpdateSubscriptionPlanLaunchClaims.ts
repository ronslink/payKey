import { MigrationInterface, QueryRunner } from 'typeorm';

export class UpdateSubscriptionPlanLaunchClaims1784592001000 implements MigrationInterface {
  name = 'UpdateSubscriptionPlanLaunchClaims1784592001000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "subscription_plans"
      SET "features" = (
        SELECT jsonb_agg(
          CASE
            WHEN feature = 'P9 Tax Cards' THEN to_jsonb('P9 Supporting Summaries'::text)
            WHEN feature = 'Automatic tax payments to KRA' THEN to_jsonb('Statutory contribution schedules'::text)
            ELSE to_jsonb(feature)
          END
        )
        FROM jsonb_array_elements_text("features") AS items(feature)
      ),
      "updatedAt" = now()
      WHERE "features" ?| array['P9 Tax Cards', 'Automatic tax payments to KRA']
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE "subscription_plans"
      SET "features" = (
        SELECT jsonb_agg(
          CASE
            WHEN feature = 'P9 Supporting Summaries' THEN to_jsonb('P9 Tax Cards'::text)
            WHEN feature = 'Statutory contribution schedules' THEN to_jsonb('Automatic tax payments to KRA'::text)
            ELSE to_jsonb(feature)
          END
        )
        FROM jsonb_array_elements_text("features") AS items(feature)
      ),
      "updatedAt" = now()
      WHERE "features" ?| array['P9 Supporting Summaries', 'Statutory contribution schedules']
    `);
  }
}
