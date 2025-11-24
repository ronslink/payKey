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
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const taxes_service_1 = require("./modules/taxes/taxes.service");
const users_service_1 = require("./modules/users/users.service");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const taxesService = app.get(taxes_service_1.TaxesService);
    const usersService = app.get(users_service_1.UsersService);
    console.log('Seeding tax tables...');
    const existingTables = await taxesService.getTaxTables();
    if (existingTables.length === 0) {
        console.log('No tax tables found. Creating default 2024/2025 table...');
        await taxesService.createTaxTable({
            year: 2024,
            effectiveDate: new Date('2024-01-01'),
            nssfConfig: {
                tierILimit: 7000,
                tierIILimit: 36000,
                rate: 0.06,
            },
            nhifConfig: {
                rate: 0.0275,
            },
            housingLevyRate: 0.015,
            payeBands: [
                { limit: 24000, rate: 0.1 },
                { limit: 32333, rate: 0.25 },
                { limit: Infinity, rate: 0.3 },
            ],
            personalRelief: 2400,
            isActive: true,
        });
        console.log('Default tax table created.');
    }
    else {
        console.log('Tax tables already exist.');
    }
    await app.close();
}
bootstrap();
//# sourceMappingURL=seed-tax-table.js.map