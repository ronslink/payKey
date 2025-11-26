import { Repository } from 'typeorm';
import { TaxConfig, TaxType } from '../entities/tax-config.entity';
export declare class TaxConfigService {
    private taxConfigRepository;
    constructor(taxConfigRepository: Repository<TaxConfig>);
    getActiveTaxConfig(taxType: TaxType, date?: Date): Promise<TaxConfig | null>;
    getAllActiveTaxConfigs(date?: Date): Promise<TaxConfig[]>;
    getTaxHistory(taxType: TaxType): Promise<TaxConfig[]>;
    createTaxConfig(configData: Partial<TaxConfig>): Promise<TaxConfig>;
    seedInitialConfigs(): Promise<void>;
}
