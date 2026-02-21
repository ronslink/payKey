import {
  MigrationInterface,
  QueryRunner,
  TableColumn,
  TableIndex,
} from 'typeorm';

/**
 * Adds promo code redemption fields across three tables:
 *
 * promotional_items
 *   - promoCode  (varchar 50, nullable, unique)
 *       Human-readable code employers enter at checkout (e.g. "XMAS2025").
 *       Unique so codes can't collide.
 *
 * subscriptions
 *   - appliedPromoId       (uuid, nullable) — FK-style reference to promotional_items.id
 *   - promoDiscountAmount  (decimal 10,2, nullable) — KES saved on this subscription
 *
 * subscription_payments
 *   - promoCodeUsed        (varchar 50, nullable) — snapshot of code used (audit; survives promo deletion)
 *   - promoDiscountAmount  (decimal 10,2, nullable) — KES discount applied on this payment
 */
export class AddPromoCodeRedemption1771800000000 implements MigrationInterface {
  name = 'AddPromoCodeRedemption1771800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // ── promotional_items ──────────────────────────────────────────────────────
    await queryRunner.addColumn(
      'promotional_items',
      new TableColumn({
        name: 'promoCode',
        type: 'varchar',
        length: '50',
        isNullable: true,
        isUnique: true,
      }),
    );

    // ── subscriptions ──────────────────────────────────────────────────────────
    await queryRunner.addColumn(
      'subscriptions',
      new TableColumn({
        name: 'appliedPromoId',
        type: 'uuid',
        isNullable: true,
      }),
    );

    await queryRunner.addColumn(
      'subscriptions',
      new TableColumn({
        name: 'promoDiscountAmount',
        type: 'decimal',
        precision: 10,
        scale: 2,
        isNullable: true,
      }),
    );

    // ── subscription_payments ──────────────────────────────────────────────────
    await queryRunner.addColumn(
      'subscription_payments',
      new TableColumn({
        name: 'promoCodeUsed',
        type: 'varchar',
        length: '50',
        isNullable: true,
      }),
    );

    await queryRunner.addColumn(
      'subscription_payments',
      new TableColumn({
        name: 'promoDiscountAmount',
        type: 'decimal',
        precision: 10,
        scale: 2,
        isNullable: true,
      }),
    );

    // Index on subscriptions.appliedPromoId for fast promo usage queries
    await queryRunner.createIndex(
      'subscriptions',
      new TableIndex({
        name: 'IDX_SUBSCRIPTIONS_APPLIED_PROMO_ID',
        columnNames: ['appliedPromoId'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex(
      'subscriptions',
      'IDX_SUBSCRIPTIONS_APPLIED_PROMO_ID',
    );

    await queryRunner.dropColumn(
      'subscription_payments',
      'promoDiscountAmount',
    );
    await queryRunner.dropColumn('subscription_payments', 'promoCodeUsed');

    await queryRunner.dropColumn('subscriptions', 'promoDiscountAmount');
    await queryRunner.dropColumn('subscriptions', 'appliedPromoId');

    await queryRunner.dropColumn('promotional_items', 'promoCode');
  }
}
