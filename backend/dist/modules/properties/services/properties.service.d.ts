import { Repository } from 'typeorm';
import { Property } from '../entities/property.entity';
import { CreatePropertyDto, UpdatePropertyDto, PropertySummaryDto } from '../dto/property.dto';
export declare class PropertiesService {
    private propertyRepository;
    constructor(propertyRepository: Repository<Property>);
    createProperty(userId: string, dto: CreatePropertyDto): Promise<Property>;
    getProperties(userId: string): Promise<Property[]>;
    getProperty(id: string, userId: string): Promise<Property>;
    updateProperty(id: string, userId: string, dto: UpdatePropertyDto): Promise<Property>;
    deleteProperty(id: string, userId: string): Promise<void>;
    getPropertySummaries(userId: string): Promise<PropertySummaryDto[]>;
}
