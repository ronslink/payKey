export declare enum TaxType {
    PAYE = "PAYE",
    SHIF = "SHIF",
    NSSF_TIER1 = "NSSF_TIER1",
    NSSF_TIER2 = "NSSF_TIER2",
    HOUSING_LEVY = "HOUSING_LEVY"
}
export declare enum RateType {
    PERCENTAGE = "PERCENTAGE",
    GRADUATED = "GRADUATED",
    TIERED = "TIERED"
}
export interface TaxBracket {
    from: number;
    to: number | null;
    rate: number;
}
export interface TaxTier {
    name: string;
    salaryFrom: number;
    salaryTo: number | null;
    rate: number;
}
export interface TaxConfiguration {
    percentage?: number;
    minAmount?: number;
    maxAmount?: number;
    brackets?: TaxBracket[];
    tiers?: TaxTier[];
    personalRelief?: number;
    insuranceRelief?: number;
    maxInsuranceRelief?: number;
}
export declare class TaxConfig {
    id: string;
    taxType: TaxType;
    rateType: RateType;
    effectiveFrom: Date;
    effectiveTo: Date;
    configuration: TaxConfiguration;
    paymentDeadline: string;
    isActive: boolean;
    notes: string;
    createdAt: Date;
    updatedAt: Date;
}
