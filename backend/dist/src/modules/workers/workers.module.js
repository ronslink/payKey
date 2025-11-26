"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WorkersModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const workers_service_1 = require("./workers.service");
const workers_controller_1 = require("./workers.controller");
const worker_entity_1 = require("./entities/worker.entity");
const termination_entity_1 = require("./entities/termination.entity");
const leave_request_entity_1 = require("./entities/leave-request.entity");
const termination_service_1 = require("./services/termination.service");
const leave_management_service_1 = require("./services/leave-management.service");
const taxes_module_1 = require("../taxes/taxes.module");
const users_module_1 = require("../users/users.module");
let WorkersModule = class WorkersModule {
};
exports.WorkersModule = WorkersModule;
exports.WorkersModule = WorkersModule = __decorate([
    (0, common_1.Module)({
        imports: [typeorm_1.TypeOrmModule.forFeature([worker_entity_1.Worker, termination_entity_1.Termination, leave_request_entity_1.LeaveRequest]), taxes_module_1.TaxesModule, users_module_1.UsersModule],
        controllers: [workers_controller_1.WorkersController],
        providers: [workers_service_1.WorkersService, termination_service_1.TerminationService, leave_management_service_1.LeaveManagementService],
        exports: [workers_service_1.WorkersService],
    })
], WorkersModule);
//# sourceMappingURL=workers.module.js.map