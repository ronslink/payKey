import { User } from '../../users/entities/user.entity';
import { Property } from '../../properties/entities/property.entity';
export declare enum EmploymentType {
    FIXED = "FIXED",
    HOURLY = "HOURLY"
}
export declare enum PaymentFrequency {
    MONTHLY = "MONTHLY",
    WEEKLY = "WEEKLY"
}
export declare enum PaymentMethod {
    MPESA = "MPESA",
    BANK = "BANK",
    CASH = "CASH"
}
export declare class Worker {
    id: string;
    employmentType: EmploymentType;
    hourlyRate: number;
    user: User;
    userId: string;
    name: string;
    phoneNumber: string;
    idNumber: string;
    kraPin: string;
    salaryGross: number;
    startDate: Date;
    isActive: boolean;
    leaveBalance: number;
    email: string;
    nssfNumber: string;
    nhifNumber: string;
    jobTitle: string;
    housingAllowance: number;
    transportAllowance: number;
    paymentFrequency: PaymentFrequency;
    paymentMethod: PaymentMethod;
    mpesaNumber: string;
    bankName: string;
    bankAccount: string;
    notes: string;
    terminationId: string;
    terminatedAt: Date;
    property: Property;
    propertyId: string;
    createdAt: Date;
    updatedAt: Date;
}
