import { EmploymentType, PaymentFrequency, PaymentMethod } from '../entities/worker.entity';
export declare class CreateWorkerDto {
    name: string;
    phoneNumber: string;
    idNumber?: string;
    kraPin?: string;
    salaryGross: number;
    employmentType?: EmploymentType;
    hourlyRate?: number;
    startDate: string;
    email?: string;
    nssfNumber?: string;
    nhifNumber?: string;
    jobTitle?: string;
    housingAllowance?: number;
    transportAllowance?: number;
    paymentFrequency?: PaymentFrequency;
    paymentMethod?: PaymentMethod;
    mpesaNumber?: string;
    bankName?: string;
    bankAccount?: string;
    notes?: string;
}
