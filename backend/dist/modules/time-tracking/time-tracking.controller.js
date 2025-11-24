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
exports.TimeTrackingController = void 0;
const common_1 = require("@nestjs/common");
const time_tracking_service_1 = require("./time-tracking.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const time_tracking_dto_1 = require("./dto/time-tracking.dto");
let TimeTrackingController = class TimeTrackingController {
    timeTrackingService;
    constructor(timeTrackingService) {
        this.timeTrackingService = timeTrackingService;
    }
    async clockIn(req, dto) {
        return this.timeTrackingService.clockIn(req.user.userId, dto);
    }
    async clockOut(req, dto) {
        return this.timeTrackingService.clockOut(req.user.userId, dto);
    }
    async getActiveEntry(req, workerId) {
        return this.timeTrackingService.getActiveEntry(req.user.userId, workerId);
    }
    async getTimeEntries(req, workerId, startDate, endDate) {
        const start = startDate ? new Date(startDate) : undefined;
        const end = endDate ? new Date(endDate) : undefined;
        return this.timeTrackingService.getTimeEntries(req.user.userId, workerId, start, end);
    }
};
exports.TimeTrackingController = TimeTrackingController;
__decorate([
    (0, common_1.Post)('clock-in'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, time_tracking_dto_1.ClockInDto]),
    __metadata("design:returntype", Promise)
], TimeTrackingController.prototype, "clockIn", null);
__decorate([
    (0, common_1.Post)('clock-out'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, time_tracking_dto_1.ClockOutDto]),
    __metadata("design:returntype", Promise)
], TimeTrackingController.prototype, "clockOut", null);
__decorate([
    (0, common_1.Get)('active'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('workerId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], TimeTrackingController.prototype, "getActiveEntry", null);
__decorate([
    (0, common_1.Get)('entries'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('workerId')),
    __param(2, (0, common_1.Query)('startDate')),
    __param(3, (0, common_1.Query)('endDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", Promise)
], TimeTrackingController.prototype, "getTimeEntries", null);
exports.TimeTrackingController = TimeTrackingController = __decorate([
    (0, common_1.Controller)('time-tracking'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [time_tracking_service_1.TimeTrackingService])
], TimeTrackingController);
//# sourceMappingURL=time-tracking.controller.js.map