"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddTerminationIdForeignKeyConstraint1735200000005 = void 0;
class AddTerminationIdForeignKeyConstraint1735200000005 {
    name = 'AddTerminationIdForeignKeyConstraint1735200000005';
    async up(queryRunner) {
        await queryRunner.query(`ALTER TABLE "workers" ADD CONSTRAINT "FK_workers_terminationId" FOREIGN KEY ("terminationId") REFERENCES "terminations"("id") ON DELETE SET NULL`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "workers" DROP CONSTRAINT "FK_workers_terminationId"`);
    }
}
exports.AddTerminationIdForeignKeyConstraint1735200000005 = AddTerminationIdForeignKeyConstraint1735200000005;
//# sourceMappingURL=1735200000005-add-termination-foreign-key.js.map