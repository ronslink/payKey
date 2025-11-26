import { IdType } from '../entities/user.entity';
export declare class UpdateComplianceProfileDto {
    kraPin: string;
    nssfNumber: string;
    nhifNumber: string;
    idType: IdType;
    idNumber: string;
    nationalityId?: string;
    address: string;
    city: string;
    countryId: string;
}
