import {
  Controller,
  Get,
  Post,
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
import { TaxConfig } from '../tax-config/entities/tax-config.entity';
import { AdminService } from './admin.service';

@Controller('api/admin/tax-configs')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminTaxConfigController {
  constructor(
    @InjectRepository(TaxConfig)
    private readonly taxConfigRepo: Repository<TaxConfig>,
    private readonly adminService: AdminService,
  ) {}

  @Get()
  getAll() {
    return this.taxConfigRepo.find({
      order: { taxType: 'ASC', effectiveFrom: 'DESC' },
    });
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async create(@Body() body: Partial<TaxConfig>, @Req() req: any) {
    const config = this.taxConfigRepo.create(body);
    const saved = await this.taxConfigRepo.save(config);

    this.adminService.logAction({
      adminUserId: req.user.id,
      action: 'CREATE',
      entityType: 'TAX_CONFIG',
      entityId: saved.id,
      newValues: saved,
      ipAddress: req.ip,
    });

    return saved;
  }

  @Put(':id')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async update(
    @Param('id') id: string,
    @Body() body: Partial<TaxConfig>,
    @Req() req: any,
  ) {
    const oldConfig = await this.taxConfigRepo.findOne({ where: { id } });
    await this.taxConfigRepo.update(id, body);
    const newConfig = await this.taxConfigRepo.findOne({ where: { id } });

    this.adminService.logAction({
      adminUserId: req.user.id,
      action: 'UPDATE',
      entityType: 'TAX_CONFIG',
      entityId: id,
      oldValues: oldConfig,
      newValues: newConfig,
      ipAddress: req.ip,
    });

    return newConfig;
  }

  @Put(':id/deactivate')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async deactivate(@Param('id') id: string, @Req() req: any) {
    const oldConfig = await this.taxConfigRepo.findOne({ where: { id } });
    await this.taxConfigRepo.update(id, {
      isActive: false,
      effectiveTo: new Date(),
    });
    const newConfig = await this.taxConfigRepo.findOne({ where: { id } });

    this.adminService.logAction({
      adminUserId: req.user.id,
      action: 'DEACTIVATE',
      entityType: 'TAX_CONFIG',
      entityId: id,
      oldValues: oldConfig,
      newValues: newConfig,
      ipAddress: req.ip,
    });

    return newConfig;
  }
}
