import { TerminationReason } from '../entities/termination.entity';
export declare class CreateTerminationDto {
    reason: TerminationReason;
    terminationDate: string;
    lastWorkingDate?: string;
    noticePeriodDays?: number;
    notes?: string;
    severancePay?: number;
    outstandingPayments?: number;
}
export declare class FinalPaymentCalculationDto {
    proratedSalary: number;
    unusedLeavePayout: number;
    severancePay: number;
    totalGross: number;
    taxDeductions: {
        nssf: number;
        nhif: number;
        housingLevy: number;
        paye: number;
        total: number;
    };
    totalNet: number;
    breakdown: {
        daysWorked: number;
        totalDaysInMonth: number;
        dailyRate: number;
        unusedLeaveDays: number;
        leavePayoutRate: number;
    };
}
