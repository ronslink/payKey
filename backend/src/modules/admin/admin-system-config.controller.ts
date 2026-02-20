import {
    Controller,
    Get,
    Put,
    Body,
    Param,
    UseGuards,
    Req,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { SystemConfig } from '../system-config/entities/system-config.entity';
import { SystemConfigService } from '../system-config/system-config.service';
import { AdminService } from './admin.service';

@Controller('api/admin/system-config')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminSystemConfigController {
    constructor(
        @InjectRepository(SystemConfig)
        private readonly configRepo: Repository<SystemConfig>,
        private readonly configService: SystemConfigService,
        private readonly adminService: AdminService,
    ) { }

    @Get()
    getAll() {
        return this.configRepo.find({ order: { key: 'ASC' } });
    }

    @Get(':key')
    getByKey(@Param('key') key: string) {
        return this.configRepo.findOne({ where: { key } });
    }

    @Put(':key')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async update(
        @Param('key') key: string,
        @Body() body: { value: string; description?: string },
        @Req() req: any,
    ) {
        const oldConfig = await this.configRepo.findOne({ where: { key } });
        await this.configService.set(key, body.value, body.description);
        const newConfig = await this.configRepo.findOne({ where: { key } });

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: oldConfig ? 'UPDATE' : 'CREATE',
            entityType: 'SYSTEM_CONFIG',
            entityId: key,
            oldValues: oldConfig,
            newValues: newConfig,
            ipAddress: req.ip,
        });

        return newConfig;
    }
}
