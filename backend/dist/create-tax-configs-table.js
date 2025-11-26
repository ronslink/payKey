"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const typeorm_1 = require("typeorm");
const dotenv_1 = require("dotenv");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
(0, dotenv_1.config)();
async function createTaxConfigsTable() {
    try {
        console.log('Connecting to database...');
        const connection = await (0, typeorm_1.createConnection)({
            type: 'postgres',
            host: process.env.DB_HOST,
            port: parseInt(process.env.DB_PORT || '5432', 10),
            username: process.env.DB_USERNAME,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            entities: [],
            synchronize: false,
            logging: true,
        });
        console.log('Connected successfully!');
        const sqlFilePath = path.join(__dirname, 'create_tax_configs.sql');
        const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
        console.log('Executing SQL...');
        const statements = sqlContent
            .split(';')
            .map(stmt => stmt.trim())
            .filter(stmt => stmt.length > 0);
        for (const statement of statements) {
            if (statement.length > 0) {
                console.log(`Executing: ${statement.substring(0, 100)}...`);
                await connection.query(statement);
            }
        }
        console.log('Tax configs table created successfully!');
        const result = await connection.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'tax_configs'
    `);
        if (result.length > 0) {
            console.log('✅ tax_configs table confirmed to exist in database');
        }
        else {
            console.log('❌ tax_configs table not found');
        }
        await connection.close();
        console.log('Database connection closed.');
    }
    catch (error) {
        console.error('Error creating tax_configs table:', error);
        process.exit(1);
    }
}
createTaxConfigsTable();
//# sourceMappingURL=create-tax-configs-table.js.map