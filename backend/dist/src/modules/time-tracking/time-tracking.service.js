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
exports.TimeTrackingService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const time_entry_entity_1 = require("./entities/time-entry.entity");
const worker_entity_1 = require("../workers/entities/worker.entity");
let TimeTrackingService = class TimeTrackingService {
    timeEntryRepository;
    workerRepository;
    constructor(timeEntryRepository, workerRepository) {
        this.timeEntryRepository = timeEntryRepository;
        this.workerRepository = workerRepository;
    }
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371e3;
        const φ1 = (lat1 * Math.PI) / 180;
        const φ2 = (lat2 * Math.PI) / 180;
        const Δφ = ((lat2 - lat1) * Math.PI) / 180;
        const Δλ = ((lon2 - lon1) * Math.PI) / 180;
        const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
    validateGeofence(currentLat, currentLon, allowedLat, allowedLon, radiusMeters = 100) {
        if (!allowedLat || !allowedLon) {
            return true;
        }
        const distance = this.calculateDistance(currentLat, currentLon, allowedLat, allowedLon);
        return distance <= radiusMeters;
    }
    async clockIn(userId, dto) {
        const worker = await this.workerRepository.findOne({
            where: { id: dto.workerId, userId },
            relations: ['property'],
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        const activeEntry = await this.timeEntryRepository.findOne({
            where: {
                workerId: dto.workerId,
                status: time_entry_entity_1.TimeEntryStatus.IN_PROGRESS,
            },
        });
        if (activeEntry) {
            throw new common_1.BadRequestException('Worker is already clocked in');
        }
        if (worker.property &&
            worker.property.latitude &&
            worker.property.longitude) {
            const isValid = this.validateGeofence(dto.latitude, dto.longitude, worker.property.latitude, worker.property.longitude, worker.property.geofenceRadius || 100);
            if (!isValid) {
                throw new common_1.BadRequestException(`You are not within the allowed area for ${worker.property.name}. Please move closer to the property.`);
            }
        }
        const timeEntry = this.timeEntryRepository.create({
            userId,
            workerId: dto.workerId,
            propertyId: worker.property?.id,
            clockInTime: new Date(),
            clockInLatitude: dto.latitude,
            clockInLongitude: dto.longitude,
            notes: dto.notes,
            status: time_entry_entity_1.TimeEntryStatus.IN_PROGRESS,
        });
        return this.timeEntryRepository.save(timeEntry);
    }
    async clockOut(userId, dto) {
        const timeEntry = await this.timeEntryRepository.findOne({
            where: { id: dto.timeEntryId, userId },
        });
        if (!timeEntry) {
            throw new common_1.NotFoundException('Time entry not found');
        }
        if (timeEntry.status === time_entry_entity_1.TimeEntryStatus.COMPLETED) {
            throw new common_1.BadRequestException('Time entry already completed');
        }
        const clockOutTime = new Date();
        const totalHours = (clockOutTime.getTime() - timeEntry.clockInTime.getTime()) /
            (1000 * 60 * 60);
        timeEntry.clockOutTime = clockOutTime;
        timeEntry.clockOutLatitude = dto.latitude;
        timeEntry.clockOutLongitude = dto.longitude;
        timeEntry.totalHours = Math.round(totalHours * 100) / 100;
        timeEntry.status = time_entry_entity_1.TimeEntryStatus.COMPLETED;
        if (dto.notes) {
            timeEntry.notes = dto.notes;
        }
        return this.timeEntryRepository.save(timeEntry);
    }
    async getActiveEntry(userId, workerId) {
        return this.timeEntryRepository.findOne({
            where: {
                userId,
                workerId,
                status: time_entry_entity_1.TimeEntryStatus.IN_PROGRESS,
            },
        });
    }
    async getTimeEntries(userId, workerId, startDate, endDate) {
        const where = { userId };
        if (workerId) {
            where.workerId = workerId;
        }
        if (startDate && endDate) {
            where.clockInTime = (0, typeorm_2.Between)(startDate, endDate);
        }
        return this.timeEntryRepository.find({
            where,
            order: { clockInTime: 'DESC' },
        });
    }
    async getWorkerTimeEntries(userId, workerId, startDate, endDate) {
        return this.getTimeEntries(userId, workerId, startDate, endDate);
    }
};
exports.TimeTrackingService = TimeTrackingService;
exports.TimeTrackingService = TimeTrackingService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(time_entry_entity_1.TimeEntry)),
    __param(1, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], TimeTrackingService);
//# sourceMappingURL=time-tracking.service.js.map