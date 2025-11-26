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
exports.WorkersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const worker_entity_1 = require("./entities/worker.entity");
let WorkersService = class WorkersService {
    workersRepository;
    constructor(workersRepository) {
        this.workersRepository = workersRepository;
    }
    async create(userId, createWorkerDto) {
        const worker = this.workersRepository.create({
            ...createWorkerDto,
            userId,
        });
        return this.workersRepository.save(worker);
    }
    async findAll(userId) {
        return this.workersRepository.find({
            where: { userId, isActive: true },
            order: { createdAt: 'DESC' },
        });
    }
    async findOne(id, userId) {
        return this.workersRepository.findOne({
            where: { id, userId },
        });
    }
    async update(id, userId, updateWorkerDto) {
        const worker = await this.workersRepository.findOne({
            where: { id, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        Object.assign(worker, updateWorkerDto);
        return this.workersRepository.save(worker);
    }
    async remove(id, userId) {
        const worker = await this.workersRepository.findOne({
            where: { id, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        await this.workersRepository.remove(worker);
    }
    async getWorkerCount(userId) {
        return this.workersRepository.count({
            where: { userId, isActive: true },
        });
    }
    async archiveWorker(id, userId) {
        const worker = await this.workersRepository.findOne({
            where: { id, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        worker.isActive = false;
        worker.terminatedAt = new Date();
        return this.workersRepository.save(worker);
    }
};
exports.WorkersService = WorkersService;
exports.WorkersService = WorkersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], WorkersService);
//# sourceMappingURL=workers.service.js.map