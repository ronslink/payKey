import { MigrationInterface, QueryRunner, TableColumn, TableIndex } from 'typeorm';

/**
 * Adds campaign dispatch tracking fields to the campaigns table:
 *
 *  - lastDispatchedAt  (timestamptz, nullable)
 *      Set by CampaignScheduler after a campaign is dispatched.
 *      NULL means the campaign has never been dispatched.
 *      Used to prevent duplicate sends.
 *
 *  - lastDispatchCount  (int, default 0)
 *      Number of recipients reached on the last dispatch run.
 */
export class AddCampaignDispatchFields1771700000000 implements MigrationInterface {
    name = 'AddCampaignDispatchFields1771700000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.addColumn(
            'campaigns',
            new TableColumn({
                name: 'lastDispatchedAt',
                type: 'timestamptz',
                isNullable: true,
            }),
        );

        await queryRunner.addColumn(
            'campaigns',
            new TableColumn({
                name: 'lastDispatchCount',
                type: 'int',
                default: 0,
            }),
        );

        // Index so the scheduler can efficiently find un-dispatched campaigns
        await queryRunner.createIndex(
            'campaigns',
            new TableIndex({
                name: 'IDX_CAMPAIGNS_LAST_DISPATCHED_AT',
                columnNames: ['lastDispatchedAt'],
            }),
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.dropIndex('campaigns', 'IDX_CAMPAIGNS_LAST_DISPATCHED_AT');
        await queryRunner.dropColumn('campaigns', 'lastDispatchCount');
        await queryRunner.dropColumn('campaigns', 'lastDispatchedAt');
    }
}
