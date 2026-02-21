import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSubscriptionStatsView1771604795196 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
            CREATE VIEW subscription_tier_stats AS
            SELECT
                s.tier,
                COUNT(s.id) as subscriber_count,
                COALESCE(SUM(s.amount), 0) as total_mrr,
                s.currency,
                COALESCE(AVG(worker_counts.w_count), 0) as avg_workers
            FROM subscriptions s
            LEFT JOIN (
                SELECT "userId", COUNT(id) as w_count 
                FROM workers 
                WHERE "isActive" = true 
                GROUP BY "userId"
            ) worker_counts ON worker_counts."userId" = s."userId"
            WHERE s.status = 'ACTIVE'
            GROUP BY s.tier, s.currency;
        `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP VIEW subscription_tier_stats`);
  }
}
