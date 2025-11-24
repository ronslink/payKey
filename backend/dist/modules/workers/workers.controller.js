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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WorkersController = void 0;
const common_1 = require("@nestjs/common");
const workers_service_1 = require("./workers.service");
const create_worker_dto_1 = require("./dto/create-worker.dto");
const termination_dto_1 = require("./dto/termination.dto");
const termination_service_1 = require("./services/termination.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const subscription_guard_1 = require("../subscriptions/subscription.guard");
let WorkersController = class WorkersController {
    workersService;
    terminationService;
    constructor(workersService, terminationService) {
        this.workersService = workersService;
        this.terminationService = terminationService;
    }
    create(req, createWorkerDto) {
        return this.workersService.create(req.user.userId, createWorkerDto);
    }
    update(req, id, updateWorkerDto) {
        return this.workersService.update(id, req.user.userId, updateWorkerDto);
    }
    remove(req, id) {
        return this.workersService.remove(id, req.user.userId);
    }
    async findAll(req, res) {
        const workers = await this.workersService.findAll(req.user.userId);
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
        res.setHeader('ETag', `"workers-${Date.now()}-${workers.length}"`);
        res.setHeader('Last-Modified', new Date().toUTCString());
        return res.json(workers);
    }
    findOne(req, id) {
        return this.workersService.findOne(id, req.user.userId);
    }
    calculateFinalPayment(req, id, terminationDate) {
        return this.terminationService.calculateFinalPayment(id, req.user.userId, new Date(terminationDate));
    }
    terminateWorker(req, id, dto) {
        return this.terminationService.terminateWorker(id, req.user.userId, dto);
    }
    getTerminationHistory(req) {
        return this.terminationService.getTerminationHistory(req.user.userId);
    }
};
exports.WorkersController = WorkersController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(subscription_guard_1.SubscriptionGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_worker_dto_1.CreateWorkerDto]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "remove", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], WorkersController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)(':id/calculate-final-payment'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)('terminationDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "calculateFinalPayment", null);
__decorate([
    (0, common_1.Post)(':id/terminate'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, termination_dto_1.CreateTerminationDto]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "terminateWorker", null);
__decorate([
    (0, common_1.Get)('terminated/history'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], WorkersController.prototype, "getTerminationHistory", null);
exports.WorkersController = WorkersController = __decorate([
    (0, common_1.Controller)('workers'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [workers_service_1.WorkersService,
        termination_service_1.TerminationService])
], WorkersController);
//# sourceMappingURL=workers.controller.js.map