import {
  MigrationInterface,
  QueryRunner,
  Table,
  TableForeignKey,
  TableIndex,
} from 'typeorm';

export class AddPromotionalItemsAndCampaigns1700000000000 implements MigrationInterface {
  name = 'AddPromotionalItemsAndCampaigns1700000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create promotional_items table
    await queryRunner.createTable(
      new Table({
        name: 'promotional_items',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          { name: 'name', type: 'varchar', length: '255' },
          { name: 'description', type: 'text', isNullable: true },
          {
            name: 'type',
            type: 'enum',
            enum: ['DISCOUNT', 'FREE_TRIAL', 'FEATURE_UNLOCK', 'CREDIT'],
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['DRAFT', 'ACTIVE', 'PAUSED', 'EXPIRED'],
            default: "'DRAFT'",
          },
          {
            name: 'discountPercentage',
            type: 'decimal',
            precision: 10,
            scale: 2,
            isNullable: true,
          },
          {
            name: 'discountAmount',
            type: 'decimal',
            precision: 10,
            scale: 2,
            isNullable: true,
          },
          { name: 'freeTrialDays', type: 'int', isNullable: true },
          { name: 'features', type: 'json', isNullable: true },
          { name: 'maxUses', type: 'int', isNullable: true },
          { name: 'currentUses', type: 'int', default: 0 },
          { name: 'validFrom', type: 'timestamptz', isNullable: true },
          { name: 'validUntil', type: 'timestamptz', isNullable: true },
          { name: 'applicableTiers', type: 'json', isNullable: true },
          { name: 'termsAndConditions', type: 'text', isNullable: true },
          { name: 'createdAt', type: 'timestamptz', default: 'now()' },
          { name: 'updatedAt', type: 'timestamptz', default: 'now()' },
        ],
      }),
      true,
    );

    // Create campaigns table
    await queryRunner.createTable(
      new Table({
        name: 'campaigns',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          { name: 'name', type: 'varchar', length: '255' },
          { name: 'description', type: 'text', isNullable: true },
          {
            name: 'type',
            type: 'enum',
            enum: [
              'BANNER',
              'POPUP',
              'EMAIL',
              'IN_APP_NOTIFICATION',
              'SIDEBAR',
            ],
          },
          {
            name: 'status',
            type: 'enum',
            enum: [
              'DRAFT',
              'SCHEDULED',
              'ACTIVE',
              'PAUSED',
              'COMPLETED',
              'CANCELLED',
            ],
            default: "'DRAFT'",
          },
          { name: 'title', type: 'varchar', length: '255' },
          { name: 'message', type: 'text' },
          { name: 'callToAction', type: 'text', isNullable: true },
          { name: 'callToActionUrl', type: 'text', isNullable: true },
          { name: 'imageUrl', type: 'text', isNullable: true },
          { name: 'targetAudience', type: 'json', isNullable: true },
          { name: 'scheduledFrom', type: 'timestamptz', isNullable: true },
          { name: 'scheduledUntil', type: 'timestamptz', isNullable: true },
          { name: 'priority', type: 'int', isNullable: true },
          { name: 'impressions', type: 'int', default: 0 },
          { name: 'clicks', type: 'int', default: 0 },
          { name: 'conversions', type: 'int', default: 0 },
          { name: 'promotionalItemId', type: 'uuid', isNullable: true },
          { name: 'displaySettings', type: 'json', isNullable: true },
          { name: 'createdAt', type: 'timestamptz', default: 'now()' },
          { name: 'updatedAt', type: 'timestamptz', default: 'now()' },
        ],
      }),
      true,
    );

    // Create foreign key for campaigns -> promotional_items
    await queryRunner.createForeignKey(
      'campaigns',
      new TableForeignKey({
        columnNames: ['promotionalItemId'],
        referencedColumnNames: ['id'],
        referencedTableName: 'promotional_items',
        onDelete: 'SET NULL',
      }),
    );

    // Create indexes for better query performance
    await queryRunner.createIndex(
      'promotional_items',
      new TableIndex({
        name: 'IDX_PROMO_ITEMS_STATUS',
        columnNames: ['status'],
      }),
    );

    await queryRunner.createIndex(
      'promotional_items',
      new TableIndex({
        name: 'IDX_PROMO_ITEMS_VALID_PERIOD',
        columnNames: ['validFrom', 'validUntil'],
      }),
    );

    await queryRunner.createIndex(
      'campaigns',
      new TableIndex({
        name: 'IDX_CAMPAIGNS_STATUS',
        columnNames: ['status'],
      }),
    );

    await queryRunner.createIndex(
      'campaigns',
      new TableIndex({
        name: 'IDX_CAMPAIGNS_SCHEDULE',
        columnNames: ['scheduledFrom', 'scheduledUntil'],
      }),
    );

    await queryRunner.createIndex(
      'campaigns',
      new TableIndex({
        name: 'IDX_CAMPAIGNS_PRIORITY',
        columnNames: ['priority'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('campaigns');
    await queryRunner.dropTable('promotional_items');
  }
}
