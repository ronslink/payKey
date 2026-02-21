import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { PropertiesService } from '../services/properties.service';
import {
  CreatePropertyDto,
  UpdatePropertyDto,
  PropertySummaryDto,
} from '../dto/property.dto';
import { Property } from '../entities/property.entity';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PlatinumGuard } from '../../auth/platinum.guard';

@Controller('properties')
@UseGuards(JwtAuthGuard, PlatinumGuard)
export class PropertiesController {
  constructor(private readonly propertiesService: PropertiesService) {
    console.log('PropertiesController initialized');
  }

  @Post()
  async createProperty(
    @Request() req: any,
    @Body() dto: CreatePropertyDto,
  ): Promise<Property> {
    return this.propertiesService.createProperty(req.user.userId, dto);
  }

  @Get()
  async getProperties(
    @Request() req: any,
    @Query('status') status?: 'active' | 'archived' | 'all',
  ): Promise<Property[]> {
    return this.propertiesService.getProperties(req.user.userId, status);
  }

  @Get('summaries')
  async getPropertySummaries(
    @Request() req: any,
    @Query('status') status?: 'active' | 'archived' | 'all',
  ): Promise<PropertySummaryDto[]> {
    return this.propertiesService.getPropertySummaries(req.user.userId, status);
  }

  @Get(':id')
  async getProperty(
    @Request() req: any,
    @Param('id') id: string,
  ): Promise<Property> {
    return this.propertiesService.getProperty(id, req.user.userId);
  }

  @Patch(':id')
  async updateProperty(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdatePropertyDto,
  ): Promise<Property> {
    return this.propertiesService.updateProperty(id, req.user.userId, dto);
  }

  @Delete(':id')
  async deleteProperty(
    @Request() req: any,
    @Param('id') id: string,
  ): Promise<void> {
    return this.propertiesService.deleteProperty(id, req.user.userId);
  }

  @Post(':id/restore')
  async restoreProperty(
    @Request() req: any,
    @Param('id') id: string,
  ): Promise<Property> {
    return this.propertiesService.restoreProperty(id, req.user.userId);
  }

  @Delete(':id/permanent')
  async permanentlyDeleteProperty(
    @Request() req: any,
    @Param('id') id: string,
  ): Promise<void> {
    return this.propertiesService.permanentlyDeleteProperty(id, req.user.userId);
  }
}
