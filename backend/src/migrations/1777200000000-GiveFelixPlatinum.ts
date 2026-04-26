import { MigrationInterface, QueryRunner } from 'typeorm';

export class GiveFelixPlatinum1777200000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    const email = 'felixowino868@gmail.com';

    // 1. Update the user's tier
    await queryRunner.query(`
      UPDATE "users" 
      SET tier = 'PLATINUM' 
      WHERE email = $1
    `, [email]);

    // 2. Try to update an existing active or trial subscription first
    const updateResult = await queryRunner.query(`
      UPDATE "subscriptions" 
      SET 
        tier = 'PLATINUM',
        status = 'ACTIVE',
        "endDate" = NOW() + INTERVAL '2 months',
        "nextBillingDate" = NOW() + INTERVAL '2 months'
      WHERE "userId" = (SELECT id FROM "users" WHERE email = $1)
      RETURNING id
    `, [email]);

    // 3. If no subscription existed to update, insert a new one
    if (updateResult.length === 0 || updateResult[1] === 0 || !updateResult[0]?.length) {
      // NOTE: Postgres UPDATE RETURNING returns an array of rows. TypeORM query() returns [rows, rowCount] or just rows.
      // Let's just blindly insert if not exists just to be safe using an UPSERT-like pattern or a conditional insert.
      await queryRunner.query(`
        INSERT INTO "subscriptions" (
          "id", "userId", "tier", "status", "startDate", "endDate", "nextBillingDate", "billingPeriod"
        )
        SELECT 
          gen_random_uuid(), id, 'PLATINUM', 'ACTIVE', NOW(), NOW() + INTERVAL '2 months', NOW() + INTERVAL '2 months', 'monthly'
        FROM "users" 
        WHERE email = $1
        AND NOT EXISTS (
          SELECT 1 FROM "subscriptions" WHERE "userId" = "users".id
        )
      `, [email]);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const email = 'felixowino868@gmail.com';
    
    // Revert user back to FREE
    await queryRunner.query(`
      UPDATE "users" 
      SET tier = 'FREE' 
      WHERE email = $1
    `, [email]);

    // We can't cleanly revert the exact subscription state without backup tables, 
    // but we can set their sub back to FREE to mimic the original state.
    await queryRunner.query(`
      UPDATE "subscriptions" 
      SET 
        tier = 'FREE',
        status = 'EXPIRED',
        "endDate" = NOW()
      WHERE "userId" = (SELECT id FROM "users" WHERE email = $1)
    `, [email]);
  }
}
