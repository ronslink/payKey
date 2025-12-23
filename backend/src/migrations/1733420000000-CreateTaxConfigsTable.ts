import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreateTaxConfigsTable1733420000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'tax_configs',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'taxType',
            type: 'enum',
            enum: ['PAYE', 'SHIF', 'NSSF_TIER1', 'NSSF_TIER2', 'HOUSING_LEVY'],
          },
          {
            name: 'rateType',
            type: 'enum',
            enum: ['PERCENTAGE', 'GRADUATED', 'TIERED'],
          },
          {
            name: 'effectiveFrom',
            type: 'date',
          },
          {
            name: 'effectiveTo',
            type: 'date',
            isNullable: true,
          },
          {
            name: 'configuration',
            type: 'jsonb',
          },
          {
            name: 'paymentDeadline',
            type: 'varchar',
            default: "'9th of following month'",
          },
          {
            name: 'isActive',
            type: 'boolean',
            default: true,
          },
          {
            name: 'notes',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'updatedAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true,
    );

    // Insert default tax configurations for Kenya (2024 rates)
    await queryRunner.query(`
      INSERT INTO tax_configs ("taxType", "rateType", "effectiveFrom", "configuration", "isActive") VALUES
      -- PAYE (Graduated)
      ('PAYE', 'GRADUATED', '2024-01-01', 
        '{"brackets": [
          {"from": 0, "to": 24000, "rate": 0.10},
          {"from": 24001, "to": 32333, "rate": 0.25},
          {"from": 32334, "to": 500000, "rate": 0.30},
          {"from": 500001, "to": 800000, "rate": 0.325},
          {"from": 800001, "to": null, "rate": 0.35}
        ], "personalRelief": 2400}', 
        true),
      
      -- NHIF/SHIF (Percentage)
      ('SHIF', 'PERCENTAGE', '2024-01-01',
        '{"percentage": 2.75, "minAmount": 0, "maxAmount": null}',
        true),
      
      -- NSSF Tier 1 (Tiered)
      ('NSSF_TIER1', 'TIERED', '2024-01-01',
        '{"tiers": [
          {"name": "Tier 1", "salaryFrom": 0, "salaryTo": 7000, "rate": 0.06}
        ]}',
        true),
      
      -- NSSF Tier 2 (Tiered)
      ('NSSF_TIER2', 'TIERED', '2024-01-01',
        '{"tiers": [
          {"name": "Tier 2", "salaryFrom": 7001, "salaryTo": 36000, "rate": 0.06}
        ]}',
        true),
      
      -- Housing Levy (Percentage)
      ('HOUSING_LEVY', 'PERCENTAGE', '2024-01-01',
        '{"percentage": 1.5, "minAmount": 0, "maxAmount": null}',
        true);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('tax_configs');
  }
}
