"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("reflect-metadata");
const typeorm_1 = require("typeorm");
const config_1 = require("@nestjs/config");
async function checkTables() {
    const configService = new config_1.ConfigService();
    const dataSource = new typeorm_1.DataSource({
        type: 'postgres',
        host: configService.get('DB_HOST', 'localhost'),
        port: configService.get('DB_PORT', 5432),
        username: configService.get('DB_USERNAME', 'postgres'),
        password: configService.get('DB_PASSWORD', 'admin'),
        database: configService.get('DB_NAME', 'paykey'),
        synchronize: false,
        logging: true,
    });
    try {
        await dataSource.initialize();
        console.log('Connected to database successfully');
        const result = await dataSource.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
        console.log('\nTables in database:');
        result.forEach((row) => {
            console.log(`- ${row.table_name}`);
        });
    }
    catch (error) {
        console.error('Error checking database:', error);
    }
    finally {
        await dataSource.destroy();
    }
}
checkTables();
//# sourceMappingURL=check-tables.js.map