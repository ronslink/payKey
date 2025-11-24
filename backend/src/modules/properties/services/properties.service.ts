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

  async getProperties(userId: string): Promise<Property[]> {
    return this.propertyRepository.find({
      where: { userId, isActive: true },
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

  async getPropertySummaries(userId: string): Promise<PropertySummaryDto[]> {
    const properties = await this.propertyRepository
      .createQueryBuilder('property')
      .leftJoinAndSelect('property.workers', 'worker')
      .where('property.userId = :userId', { userId })
      .andWhere('property.isActive = :isActive', { isActive: true })
      .loadRelationCountAndMap('property.workerCount', 'property.workers')
      .getMany();

    return properties.map((p) => ({
      id: p.id,
      name: p.name,
      address: p.address,
      workerCount: (p as any).workerCount || 0,
      isActive: p.isActive,
    }));
  }
}
