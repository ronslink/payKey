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
    logging: true,
});
async function listTables() {
    try {
        await dataSource.initialize();
        console.log('Connected to database successfully!');
        const query = `
      SELECT table_name, table_schema 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `;
        const result = await dataSource.query(query);
        console.log('\n📊 Current Database Tables:');
        console.log('='.repeat(50));
        result.forEach((row, index) => {
            console.log(`${index + 1}. ${row.table_name} (${row.table_schema})`);
        });
        console.log(`\nTotal tables: ${result.length}`);
        const tableNames = result.map((row) => row.table_name);
        const targetTables = [
            'leave_requests',
            'terminations',
            'account_mappings',
            'accounting_exports',
            'tax_payments'
        ];
        console.log('\n🎯 Missing Tables Status:');
        console.log('='.repeat(50));
        targetTables.forEach((table) => {
            if (tableNames.includes(table)) {
                console.log(`✅ ${table} - EXISTS`);
            }
            else {
                console.log(`❌ ${table} - MISSING`);
            }
        });
    }
    catch (error) {
        console.error('Error connecting to database:', error.message);
    }
    finally {
        await dataSource.destroy();
    }
}
listTables();
//# sourceMappingURL=check-database-tables.js.map