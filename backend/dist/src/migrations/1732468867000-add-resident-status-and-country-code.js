"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddResidentStatusAndCountryCode1732468867000 = void 0;
class AddResidentStatusAndCountryCode1732468867000 {
    name = 'AddResidentStatusAndCountryCode1732468867000';
    async up(queryRunner) {
        await queryRunner.query(`ALTER TABLE "users" ADD COLUMN "residentStatus" "public"."users_residentstatus_enum"`);
        await queryRunner.query(`ALTER TABLE "users" ADD COLUMN "countryCode" character varying`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "countryCode"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "residentStatus"`);
    }
}
exports.AddResidentStatusAndCountryCode1732468867000 = AddResidentStatusAndCountryCode1732468867000;
//# sourceMappingURL=1732468867000-add-resident-status-and-country-code.js.map