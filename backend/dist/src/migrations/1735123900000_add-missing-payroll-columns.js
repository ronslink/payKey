"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddMissingPayrollColumns1735123900000 = void 0;
class AddMissingPayrollColumns1735123900000 {
    name = 'AddMissingPayrollColumns1735123900000';
    async up(queryRunner) {
        await queryRunner.query(`ALTER TABLE "payroll_records" ADD COLUMN "payPeriodId" uuid`);
        await queryRunner.query(`ALTER TABLE "payroll_records" ADD COLUMN "bonuses" decimal(10,2) DEFAULT 0`);
        await queryRunner.query(`ALTER TABLE "payroll_records" ADD COLUMN "otherEarnings" decimal(10,2) DEFAULT 0`);
        await queryRunner.query(`ALTER TABLE "payroll_records" ADD COLUMN "otherDeductions" decimal(10,2) DEFAULT 0`);
        await queryRunner.query(`ALTER TABLE "payroll_records" ADD COLUMN "status" varchar DEFAULT 'draft'`);
        await queryRunner.query(`ALTER TABLE "payroll_records" ADD COLUMN "finalizedAt" TIMESTAMP WITH TIME ZONE`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "payroll_records" DROP COLUMN "finalizedAt"`);
        await queryRunner.query(`ALTER TABLE "payroll_records" DROP COLUMN "status"`);
        await queryRunner.query(`ALTER TABLE "payroll_records" DROP COLUMN "otherDeductions"`);
        await queryRunner.query(`ALTER TABLE "payroll_records" DROP COLUMN "otherEarnings"`);
        await queryRunner.query(`ALTER TABLE "payroll_records" DROP COLUMN "bonuses"`);
        await queryRunner.query(`ALTER TABLE "payroll_records" DROP COLUMN "payPeriodId"`);
    }
}
exports.AddMissingPayrollColumns1735123900000 = AddMissingPayrollColumns1735123900000;
//# sourceMappingURL=1735123900000_add-missing-payroll-columns.js.map