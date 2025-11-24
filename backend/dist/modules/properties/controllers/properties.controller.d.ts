import { PropertiesService } from '../services/properties.service';
import { CreatePropertyDto, UpdatePropertyDto, PropertySummaryDto } from '../dto/property.dto';
import { Property } from '../entities/property.entity';
export declare class PropertiesController {
    private readonly propertiesService;
    constructor(propertiesService: PropertiesService);
    createProperty(req: any, dto: CreatePropertyDto): Promise<Property>;
    getProperties(req: any): Promise<Property[]>;
    getPropertySummaries(req: any): Promise<PropertySummaryDto[]>;
    getProperty(req: any, id: string): Promise<Property>;
    updateProperty(req: any, id: string, dto: UpdatePropertyDto): Promise<Property>;
    deleteProperty(req: any, id: string): Promise<void>;
}
