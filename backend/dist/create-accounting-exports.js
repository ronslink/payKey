"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const typeorm_1 = require("typeorm");
const dataSource = new typeorm_1.DataSource({
    type: 'postgres',
    host: 'localhost',
    port: 5435,
    username: 'postgres',
    password: 'admin',
    database: 'paykey',
    synchronize: false,
    entities: [],
});
async function createAccountingExportsTable() {
    try {
        await dataSource.initialize();
        console.log('Connected to database successfully!');
        console.log('\n🔧 Creating accounting_exports table...');
        try {
            await dataSource.query(`
        CREATE TYPE accounting_exports_export_type_enum AS ENUM('PAYROLL_SUMMARY', 'TAX_REPORT', 'COST_ANALYSIS', 'LEDGER_EXPORT', 'BALANCE_SHEET', 'P_L_STATEMENT');
      `);
            console.log('✅ Created accounting_exports_export_type_enum');
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ accounting_exports_export_type_enum already exists');
            }
            else {
                console.error('Error creating export_type enum:', error.message);
            }
        }
        try {
            await dataSource.query(`
        CREATE TYPE accounting_exports_status_enum AS ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');
      `);
            console.log('✅ Created accounting_exports_status_enum');
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ accounting_exports_status_enum already exists');
            }
            else {
                console.error('Error creating status enum:', error.message);
            }
        }
        try {
            await dataSource.query(`
        CREATE TYPE accounting_exports_format_enum AS ENUM('CSV', 'EXCEL', 'PDF', 'JSON', 'XML');
      `);
            console.log('✅ Created accounting_exports_format_enum');
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ accounting_exports_format_enum already exists');
            }
            else {
                console.error('Error creating format enum:', error.message);
            }
        }
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
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ accounting_exports table already exists');
            }
            else {
                console.error('Error creating table:', error.message);
                return;
            }
        }
        try {
            await dataSource.query(`CREATE INDEX idx_accounting_exports_userId ON accounting_exports (userId)`);
            await dataSource.query(`CREATE INDEX idx_accounting_exports_status ON accounting_exports (status)`);
            await dataSource.query(`CREATE INDEX idx_accounting_exports_exportType ON accounting_exports (exportType)`);
            await dataSource.query(`CREATE INDEX idx_accounting_exports_createdAt ON accounting_exports (createdAt)`);
            console.log('✅ Created accounting_exports indexes');
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ accounting_exports indexes already exist');
            }
            else {
                console.error('Error creating indexes:', error.message);
            }
        }
        try {
            await dataSource.query(`
        ALTER TABLE accounting_exports ADD CONSTRAINT FK_accounting_exports_userId 
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE;
      `);
            console.log('✅ Created FK_accounting_exports_userId constraint');
        }
        catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ FK_accounting_exports_userId constraint already exists');
            }
            else {
                console.error('Error creating foreign key:', error.message);
            }
        }
        console.log('\n🎉 accounting_exports table created successfully!');
    }
    catch (error) {
        console.error('Error:', error.message);
    }
    finally {
        await dataSource.destroy();
    }
}
createAccountingExportsTable();
//# sourceMappingURL=create-accounting-exports.js.map