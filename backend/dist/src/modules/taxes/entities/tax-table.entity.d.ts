export interface NssfConfig {
    tierILimit: number;
    tierIILimit: number;
    rate: number;
}
export interface NhifConfig {
    rate: number;
}
export interface PayeBand {
    limit: number;
    rate: number;
}
export declare class TaxTable {
    id: string;
    year: number;
    effectiveDate: Date;
    nssfConfig: NssfConfig;
    nhifConfig: NhifConfig;
    housingLevyRate: number;
    payeBands: PayeBand[];
    personalRelief: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
