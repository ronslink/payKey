"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddIsOnboardingCompletedToUser1732467840000 = void 0;
class AddIsOnboardingCompletedToUser1732467840000 {
    name = 'AddIsOnboardingCompletedToUser1732467840000';
    async up(queryRunner) {
        await queryRunner.query(`ALTER TABLE "users" ADD "isOnboardingCompleted" boolean NOT NULL DEFAULT false`);
    }
    async down(queryRunner) {
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "isOnboardingCompleted"`);
    }
}
exports.AddIsOnboardingCompletedToUser1732467840000 = AddIsOnboardingCompletedToUser1732467840000;
//# sourceMappingURL=1732467840000-AddIsOnboardingCompletedToUser.js.map