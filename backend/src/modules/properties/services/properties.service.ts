import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Property } from '../entities/property.entity';
import {
  CreatePropertyDto,
  UpdatePropertyDto,
  PropertySummaryDto,
} from '../dto/property.dto';

@Injectable()
export class PropertiesService {
  constructor(
    @InjectRepository(Property)
    private propertyRepository: Repository<Property>,
  ) {}

  async createProperty(
    userId: string,
    dto: CreatePropertyDto,
  ): Promise<Property> {
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
