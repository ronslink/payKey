import { TaxConfigService } from '../services/tax-config.service';
import { TaxConfig, TaxType } from '../entities/tax-config.entity';
export declare class TaxConfigController {
    private readonly taxConfigService;
    constructor(taxConfigService: TaxConfigService);
    getActiveTaxConfigs(): Promise<TaxConfig[]>;
    getTaxHistory(taxType: TaxType): Promise<TaxConfig[]>;
    seedInitialConfigs(): Promise<{
        message: string;
    }>;
}
