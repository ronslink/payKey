import { DataSource } from 'typeorm';

const dataSource = new DataSource({
  type: 'postgres',
  host: 'localhost',
  port: 5435,
  username: 'postgres',
  password: 'admin',
  database: 'paykey',
  synchronize: false,
  entities: [],
});

async function createMissingTables() {
  try {
    await dataSource.initialize();
    console.log('Connected to database successfully!');

    // Create account_mappings table
    console.log('\n🔧 Creating account_mappings table...');

    // Create the enum type (check if exists first)
    try {
      await dataSource.query(`
        CREATE TYPE account_mappings_mapping_type_enum AS ENUM(
          'EXPENSE_ACCOUNT', 
          'ASSET_ACCOUNT', 
          'LIABILITY_ACCOUNT', 
          'REVENUE_ACCOUNT', 
          'COST_CENTER'
        );
      `);
      console.log('✅ Created account_mappings_mapping_type_enum');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log('✅ account_mappings_mapping_type_enum already exists');
      } else {
        throw error;
      }
    }

    // Create the table (check if exists first)
    try {
      await dataSource.query(`
        CREATE TABLE account_mappings (
          id uuid NOT NULL DEFAULT gen_random_uuid(),
          userId uuid NOT NULL,
          name varchar NOT NULL,
          mappingType account_mappings_mapping_type_enum NOT NULL,
          accountCode varchar NOT NULL,
          description text,
          isActive boolean DEFAULT true,
          parentAccountId uuid,
          balance decimal(15,2) DEFAULT 0,
          createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT PK_account_mappings_id PRIMARY KEY (id)
        );
      `);
      console.log('✅ Created account_mappings table');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log('✅ account_mappings table already exists');
      } else {
        throw error;
      }
    }

    // Create indexes
    try {
      await dataSource.query(
        `CREATE INDEX idx_account_mappings_userId ON account_mappings (userId)`,
      );
      await dataSource.query(
        `CREATE INDEX idx_account_mappings_mappingType ON account_mappings (mappingType)`,
      );
      await dataSource.query(
        `CREATE INDEX idx_account_mappings_accountCode ON account_mappings (accountCode)`,
      );
      console.log('✅ Created account_mappings indexes');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log('✅ account_mappings indexes already exist');
      } else {
        throw error;
      }
    }

    // Add foreign key constraint
    try {
      await dataSource.query(`
        ALTER TABLE account_mappings ADD CONSTRAINT FK_account_mappings_userId 
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE;
      `);
      console.log('✅ Created FK_account_mappings_userId constraint');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log('✅ FK_account_mappings_userId constraint already exists');
      } else {
        throw error;
      }
    }

    // Create accounting_exports table
    console.log('\n🔧 Creating accounting_exports table...');

    // Create enum types
    const enums = [
      {
        name: 'accounting_exports_export_type_enum',
        values:
          'PAYROLL_SUMMARY, TAX_REPORT, COST_ANALYSIS, LEDGER_EXPORT, BALANCE_SHEET, P&L_STATEMENT',
      },
      {
        name: 'accounting_exports_status_enum',
        values: 'PENDING, PROCESSING, COMPLETED, FAILED',
      },
      {
        name: 'accounting_exports_format_enum',
        values: 'CSV, EXCEL, PDF, JSON, XML',
      },
    ];

    for (const enumData of enums) {
      try {
        await dataSource.query(`
          CREATE TYPE ${enumData.name} AS ENUM(${enumData.values});
        `);
        console.log(`✅ Created ${enumData.name}`);
      } catch (error: any) {
        if (error.message.includes('already exists')) {
          console.log(`✅ ${enumData.name} already exists`);
        } else {
          throw error;
        }
      }
    }

    // Create the table
    try {
      await dataSource.query(`
        CREATE TABLE accounting_exports (
          id uuid NOT NULL DEFAULT gen_random_uuid(),
          userId uuid NOT NULL,
          exportType accounting_exports_export_type_enum NOT NULL,
          status accounting_exports_status_enum NOT NULL DEFAULT 'PENDING',
          format accounting_exports_format_enum NOT NULL,
          startDate date,
          endDate date,
          fileName varchar,
          filePath varchar,
          fileSize bigint,
          recordCount integer DEFAULT 0,
          errorMessage text,
          exportSettings jsonb,
          completedAt TIMESTAMP WITH TIME ZONE,
          createdAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updatedAt TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT PK_accounting_exports_id PRIMARY KEY (id)
        );
      `);
      console.log('✅ Created accounting_exports table');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log('✅ accounting_exports table already exists');
      } else {
        throw error;
      }
    }

    // Create indexes
    try {
      await dataSource.query(
        `CREATE INDEX idx_accounting_exports_userId ON accounting_exports (userId)`,
      );
      await dataSource.query(
        `CREATE INDEX idx_accounting_exports_status ON accounting_exports (status)`,
      );
      await dataSource.query(
        `CREATE INDEX idx_accounting_exports_exportType ON accounting_exports (exportType)`,
      );
      await dataSource.query(
        `CREATE INDEX idx_accounting_exports_createdAt ON accounting_exports (createdAt)`,
      );
      console.log('✅ Created accounting_exports indexes');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log('✅ accounting_exports indexes already exist');
      } else {
        throw error;
      }
    }

    // Add foreign key constraint
    try {
      await dataSource.query(`
        ALTER TABLE accounting_exports ADD CONSTRAINT FK_accounting_exports_userId 
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE;
      `);
      console.log('✅ Created FK_accounting_exports_userId constraint');
    } catch (error: any) {
      if (error.message.includes('already exists')) {
        console.log(
          '✅ FK_accounting_exports_userId constraint already exists',
        );
      } else {
        throw error;
      }
    }

    // Verify tables exist
    console.log('\n🔍 Verifying tables...');
    const result: any[] = await dataSource.query(`
      SELECT table_name, table_schema 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('account_mappings', 'accounting_exports')
      ORDER BY table_name;
    `);

    console.log('\n📊 Created Tables:');
    result.forEach((row: any) => {
      console.log(`✅ ${row.table_name} - EXISTS`);
    });

    console.log('\n🎉 All missing tables created successfully!');
  } catch (error: any) {
    console.error('Error:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

createMissingTables();
