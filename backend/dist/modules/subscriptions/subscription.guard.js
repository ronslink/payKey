"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SubscriptionGuard = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const users_service_1 = require("../users/users.service");
const workers_service_1 = require("../workers/workers.service");
const subscription_plans_config_1 = require("./subscription-plans.config");
let SubscriptionGuard = class SubscriptionGuard {
    reflector;
    usersService;
    workersService;
    constructor(reflector, usersService, workersService) {
        this.reflector = reflector;
        this.usersService = usersService;
        this.workersService = workersService;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        if (!user) {
            throw new common_1.ForbiddenException('User not authenticated');
        }
        const userDetails = await this.usersService.findOneById(user.userId);
        if (!userDetails) {
            throw new common_1.ForbiddenException('User not found');
        }
        const userCreatedAt = userDetails.createdAt;
        const trialEndDate = new Date(userCreatedAt);
        trialEndDate.setDate(trialEndDate.getDate() + 14);
        const isInTrialPeriod = new Date() <= trialEndDate;
        if (isInTrialPeriod) {
            return true;
        }
        const currentWorkerCount = await this.workersService.getWorkerCount(user.userId);
        const canAdd = (0, subscription_plans_config_1.canAddWorker)(userDetails.tier, currentWorkerCount);
        if (!canAdd) {
            throw new common_1.ForbiddenException(`Your ${userDetails.tier} subscription allows up to ${subscription_plans_config_1.SUBSCRIPTION_PLANS.find((p) => p.tier === userDetails.tier)
                ?.workerLimit} workers. Please upgrade to add more workers.`);
        }
        return true;
    }
};
exports.SubscriptionGuard = SubscriptionGuard;
exports.SubscriptionGuard = SubscriptionGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [core_1.Reflector,
        users_service_1.UsersService,
        workers_service_1.WorkersService])
], SubscriptionGuard);
//# sourceMappingURL=subscription.guard.js.map