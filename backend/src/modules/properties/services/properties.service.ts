import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Property } from '../entities/property.entity';
import {
  CreatePropertyDto,
  UpdatePropertyDto,
  PropertySummaryDto,
} from '../dto/property.dto';

const MIN_GEOFENCE_RADIUS_METERS = 10;
const MAX_GEOFENCE_RADIUS_METERS = 5000;

@Injectable()
export class PropertiesService {
  constructor(
    @InjectRepository(Property)
    private propertyRepository: Repository<Property>,
  ) {}

  /**
   * This controller has no ValidationPipe, so the DTO decorators are
   * documentation only. A malformed geofence anchor silently disables clock-in
   * for every worker at the property, so it is checked here.
   */
  private assertGeofenceInput(dto: {
    latitude?: number;
    longitude?: number;
    geofenceRadius?: number;
  }): void {
    const { latitude, longitude, geofenceRadius } = dto;

    if (latitude !== undefined || longitude !== undefined) {
      if (latitude === undefined || longitude === undefined) {
        throw new BadRequestException(
          'A geofence pin needs both a latitude and a longitude',
        );
      }
      if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
        throw new BadRequestException('Latitude must be between -90 and 90');
      }
      if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
        throw new BadRequestException('Longitude must be between -180 and 180');
      }
    }

    if (
      geofenceRadius !== undefined &&
      (!Number.isFinite(geofenceRadius) ||
        geofenceRadius < MIN_GEOFENCE_RADIUS_METERS ||
        geofenceRadius > MAX_GEOFENCE_RADIUS_METERS)
    ) {
      throw new BadRequestException(
        `Geofence radius must be between ${MIN_GEOFENCE_RADIUS_METERS} and ${MAX_GEOFENCE_RADIUS_METERS} meters`,
      );
    }
  }

  async createProperty(
    userId: string,
    dto: CreatePropertyDto,
  ): Promise<Property> {
    this.assertGeofenceInput(dto);

    const property = this.propertyRepository.create({
      userId,
      ...dto,
    });
    return this.propertyRepository.save(property);
  }

  async getProperties(
    userId: string,
    status?: 'active' | 'archived' | 'all',
  ): Promise<Property[]> {
    const whereClause: any = { userId };
    if (status === 'archived') {
      whereClause.isActive = false;
    } else if (status !== 'all') {
      whereClause.isActive = true;
    }

    return this.propertyRepository.find({
      where: whereClause,
      order: { name: 'ASC' },
      relations: ['workers'],
    });
  }

  async getProperty(id: string, userId: string): Promise<Property> {
    const property = await this.propertyRepository.findOne({
      where: { id, userId },
      relations: ['workers'],
    });

    if (!property) {
      throw new NotFoundException('Property not found');
    }

    return property;
  }

  async updateProperty(
    id: string,
    userId: string,
    dto: UpdatePropertyDto,
  ): Promise<Property> {
    this.assertGeofenceInput(dto);

    const property = await this.getProperty(id, userId);

    Object.assign(property, dto);
    return this.propertyRepository.save(property);
  }

  async deleteProperty(id: string, userId: string): Promise<void> {
    const property = await this.getProperty(id, userId);
    property.isActive = false;
    await this.propertyRepository.save(property);
  }

  async restoreProperty(id: string, userId: string): Promise<Property> {
    const property = await this.propertyRepository.findOne({
      where: { id, userId },
    });
    if (!property) {
      throw new NotFoundException('Property not found');
    }
    property.isActive = true;
    return this.propertyRepository.save(property);
  }

  async permanentlyDeleteProperty(id: string, userId: string): Promise<void> {
    const property = await this.propertyRepository.findOne({
      where: { id, userId },
    });
    if (!property) {
      throw new NotFoundException('Property not found');
    }
    await this.propertyRepository.remove(property);
  }

  async getPropertySummaries(
    userId: string,
    status?: 'active' | 'archived' | 'all',
  ): Promise<PropertySummaryDto[]> {
    const query = this.propertyRepository
      .createQueryBuilder('property')
      .leftJoinAndSelect('property.workers', 'worker')
      .where('property.userId = :userId', { userId });

    if (status === 'archived') {
      query.andWhere('property.isActive = :isActive', { isActive: false });
    } else if (status !== 'all') {
      query.andWhere('property.isActive = :isActive', { isActive: true });
    }

    query.loadRelationCountAndMap('property.workerCount', 'property.workers');
    const properties = await query.getMany();

    return properties.map((p) => ({
      id: p.id,
      name: p.name,
      address: p.address,
      workerCount: (p as any).workerCount || 0,
      isActive: p.isActive,
    }));
  }
}
